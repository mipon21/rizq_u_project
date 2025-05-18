import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust if needed
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:intl/intl.dart';
import '../utils/constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';

class RestaurantProfileModel {
  final String uid;
  final String name;
  final String address;
  final String logoUrl;
  final String subscriptionPlan; // e.g., 'free_trial', 'plan_100'
  final String subscriptionStatus; // e.g., 'active', 'inactive', 'free_trial'
  final int currentScanCount;
  final DateTime? trialStartDate;
  final DateTime createdAt;
  final String bankDetails; // New field for bank details

  RestaurantProfileModel({
    required this.uid,
    required this.name,
    required this.address,
    required this.logoUrl,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.currentScanCount,
    this.trialStartDate,
    required this.createdAt,
    this.bankDetails = '', // Default to empty string
  });

  factory RestaurantProfileModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return RestaurantProfileModel(
      uid: data['uid'] ?? snapshot.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      subscriptionPlan: data['subscriptionPlan'] ?? 'free_trial',
      subscriptionStatus: data['subscriptionStatus'] ?? 'inactive',
      currentScanCount: data['currentScanCount'] ?? 0,
      trialStartDate: (data['trialStartDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(), // Fallback for older docs
      bankDetails:
          data['bankDetails'] ?? '', // Get bank details or default to empty
    );
  }

  // Calculated properties
  int get rewardsIssued =>
      currentScanCount ~/ 10; // Assuming 10 points per reward
  bool get isSubscriptionActive =>
      subscriptionStatus == 'active' || isTrialActive;
  bool get isTrialActive {
    if (subscriptionStatus != 'free_trial' || trialStartDate == null) {
      return false;
    }
    // Check if trial period (e.g., 60 days) is still valid
    return DateTime.now().difference(trialStartDate!).inDays <= 60;
  }

  // Example: Get remaining trial days
  int get remainingTrialDays {
    if (!isTrialActive || trialStartDate == null) return 0;
    final expiryDate = trialStartDate!.add(const Duration(days: 60));
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}

// For Claim History
class ClaimModel {
  final String id;
  final String customerId;
  final String restaurantId;
  final String restaurantName;
  final String rewardType;
  final DateTime claimDate;
  final int pointsUsed;
  final bool isVerified;
  final DateTime? verifiedDate;

  ClaimModel({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.restaurantName,
    required this.rewardType,
    required this.claimDate,
    required this.pointsUsed,
    this.isVerified = false,
    this.verifiedDate,
  });

  String get formattedDate =>
      DateFormat('MMM d, yyyy - hh:mm a').format(claimDate);

  String get verificationCode => id.substring(0, 6).toUpperCase();

  String get formattedVerifiedDate => verifiedDate != null
      ? DateFormat('MMM d, yyyy - hh:mm a').format(verifiedDate!)
      : '';
}

class RestaurantController extends GetxController {
  static RestaurantController get instance => Get.find();
  final AuthController _authController = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final RxBool isLoadingProfile = false.obs;
  final RxBool isLoadingScan = false.obs;
  final RxBool isLoadingUpload = false.obs;
  final Rx<RestaurantProfileModel?> restaurantProfile =
      Rx<RestaurantProfileModel?>(null);

  final RxBool isLoadingClaims = false.obs;
  final RxList<ClaimModel> claimedRewards = <ClaimModel>[].obs;

  final RxBool isVerifying = false.obs;
  final RxString verificationResult = ''.obs;
  final RxBool showVerificationResult = false.obs;

  // --- Dashboard Data ---
  final RxList<Map<String, String>> recentScans = <Map<String, String>>[].obs;
  final RxList<FlSpot> scanChartData = <FlSpot>[].obs;

  String get restaurantUid => _authController.currentUserUid;

  // Expose profile details reactively
  String get name => restaurantProfile.value?.name ?? '';
  String get address => restaurantProfile.value?.address ?? '';
  String get logoUrl => restaurantProfile.value?.logoUrl ?? '';
  String get subscriptionStatus =>
      restaurantProfile.value?.subscriptionStatus ?? 'inactive';
  String get bankDetails => restaurantProfile.value?.bankDetails ?? '';
  bool get isSubscribed =>
      restaurantProfile.value?.isSubscriptionActive ?? false;
  int get scanCount => restaurantProfile.value?.currentScanCount ?? 0;
  int get rewardsIssuedCount => restaurantProfile.value?.rewardsIssued ?? 0;

  // Cache for customer data to avoid repeated queries
  final Map<String, String> _customerCache = {};

  @override
  void onInit() {
    super.onInit();

    // Initialize with empty data first to avoid null issues
    restaurantProfile.value = null;
    claimedRewards.assignAll([]);
    recentScans.clear();
    scanChartData.clear();

    if (restaurantUid.isNotEmpty) {
      // Use Future.delayed to ensure this runs after widget tree is built
      Future.delayed(Duration.zero, () {
        fetchRestaurantProfile();
        fetchClaimedRewards();
        fetchRecentScans();
        fetchScanChartData();
      });
    }

    // Re-fetch if user changes using the NEW public getter
    ever(_authController.reactiveFirebaseUser, (User? user) {
      if (user != null) {
        fetchRestaurantProfile();
        fetchClaimedRewards();
        fetchRecentScans();
        fetchScanChartData();
      } else {
        // Clear data if logged out
        if (kDebugMode) {
          print(
              "Auth state changed: User logged out. Clearing restaurant data.");
        }
        restaurantProfile.value = null;
        claimedRewards.clear();
        recentScans.clear();
        scanChartData.clear();
      }
    });

    // Add persistent data check to catch release mode issues
    ever(isLoadingProfile, (bool loading) {
      if (!loading &&
          restaurantProfile.value == null &&
          restaurantUid.isNotEmpty) {
        // If loading finished but profile is still null, try once more
        // This helps in release mode where reactivity might not work as expected
        print("Profile still null after loading - retrying fetch");
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchRestaurantProfile();
          fetchRecentScans();
          fetchScanChartData();
        });
      }
    });
  }

  Future<bool> fetchRestaurantProfile() async {
    if (restaurantUid.isEmpty) return false;

    // Set loading state
    isLoadingProfile.value = true;

    try {
      // Direct Firestore instance reference - important for release mode
      final firestore = FirebaseFirestore.instance;

      print("Fetching profile for restaurant: $restaurantUid");

      // Enable offline persistence with unlimited cache size
      try {
        firestore.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
      } catch (e) {
        // Settings might already be initialized, which can throw an error
        print("Firestore settings error (can be ignored): $e");
      }

      // Get restaurant document with server and cache option
      final restaurantDoc =
          firestore.collection('restaurants').doc(restaurantUid);

      try {
        // First try to get the document with server as source
        final docFromServer =
            await restaurantDoc.get(GetOptions(source: Source.server));

        if (docFromServer.exists) {
          _parseAndSetProfile(docFromServer);
          return true;
        }
      } catch (serverError) {
        // If server fetch fails, try cache
        print("Server fetch failed, trying cache: $serverError");
      }

      // Try cache if server failed or document didn't exist
      try {
        final docFromCache =
            await restaurantDoc.get(GetOptions(source: Source.cache));

        if (docFromCache.exists) {
          _parseAndSetProfile(docFromCache);
          return true;
        }
      } catch (cacheError) {
        print("Cache fetch failed: $cacheError");
      }

      // If both failed or document doesn't exist, try default fetch
      final doc = await restaurantDoc.get();

      if (doc.exists) {
        _parseAndSetProfile(doc);
        return true;
      } else {
        restaurantProfile.value = null; // Clear if not found
        print("Restaurant profile not found for UID: $restaurantUid");
        return false;
      }
    } catch (e) {
      print("Error fetching restaurant profile $restaurantUid: $e");
      Get.snackbar('Error', 'Failed to fetch restaurant profile');
      return false;
    } finally {
      isLoadingProfile.value = false;
      // Force update to ensure UI refreshes
      update();
    }
  }

  // Helper method to parse and set profile data
  void _parseAndSetProfile(DocumentSnapshot doc) {
    try {
      restaurantProfile.value = RestaurantProfileModel.fromSnapshot(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );

      print("Successfully loaded profile for ${restaurantProfile.value?.name}");

      // Check and update trial status if expired
      _checkAndUpdateTrialStatus();

      // Force update to ensure UI refreshes
      update();
    } catch (parseError) {
      print("Error parsing restaurant data: $parseError");
      restaurantProfile.value = null;
      Get.snackbar('Data Error', 'Could not read restaurant data correctly');
    }
  }

  // Helper to automatically transition from 'free_trial' to 'inactive' if needed
  Future<void> _checkAndUpdateTrialStatus() async {
    final profile = restaurantProfile.value;
    if (profile != null &&
        profile.subscriptionStatus == 'free_trial' &&
        !profile.isTrialActive) {
      if (kDebugMode) {
        print(
          "Free trial expired for restaurant ${profile.uid}. Updating status to inactive.",
        );
      }
      try {
        await _firestore.collection('restaurants').doc(profile.uid).update({
          'subscriptionStatus': 'inactive',
        });
        // Re-fetch profile to update UI state
        await fetchRestaurantProfile();
      } catch (e) {
        if (kDebugMode) {
          print("Error updating expired trial status for ${profile.uid}: $e");
        }
        // Maybe show a non-blocking warning?
      }
    }
  }

  Future<void> updateRestaurantDetails(
    String newName,
    String newAddress,
  ) async {
    if (restaurantUid.isEmpty) return;
    isLoadingProfile.value = true; // Use profile loading state
    try {
      await _firestore.collection('restaurants').doc(restaurantUid).update({
        'name': newName,
        'address': newAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Update local state immediately for better UX
      if (restaurantProfile.value != null) {
        restaurantProfile.value = RestaurantProfileModel(
          uid: restaurantProfile.value!.uid,
          name: newName, // Update name
          address: newAddress, // Update address
          logoUrl: restaurantProfile.value!.logoUrl,
          subscriptionPlan: restaurantProfile.value!.subscriptionPlan,
          subscriptionStatus: restaurantProfile.value!.subscriptionStatus,
          currentScanCount: restaurantProfile.value!.currentScanCount,
          trialStartDate: restaurantProfile.value!.trialStartDate,
          createdAt: restaurantProfile.value!.createdAt,
          bankDetails:
              restaurantProfile.value!.bankDetails, // Preserve bank details
        );
        restaurantProfile.refresh(); // Notify listeners
      }
      Get.snackbar('Success', 'Restaurant details updated.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update details: $e');
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> pickAndUploadLogo() async {
    if (restaurantUid.isEmpty) return;
    isLoadingUpload.value = true;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        final File imageFile = File(image.path);
        final String fileName =
            '$restaurantUid-logo-${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = _storage.ref().child(
              'restaurant_logos/$fileName',
            );

        final UploadTask uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore
        await _firestore.collection('restaurants').doc(restaurantUid).update({
          'logoUrl': downloadUrl,
        });

        // Update local state
        if (restaurantProfile.value != null) {
          restaurantProfile.value = RestaurantProfileModel(
            uid: restaurantProfile.value!.uid,
            name: restaurantProfile.value!.name,
            address: restaurantProfile.value!.address,
            logoUrl: downloadUrl, // Update logo URL
            subscriptionPlan: restaurantProfile.value!.subscriptionPlan,
            subscriptionStatus: restaurantProfile.value!.subscriptionStatus,
            currentScanCount: restaurantProfile.value!.currentScanCount,
            trialStartDate: restaurantProfile.value!.trialStartDate,
            createdAt: restaurantProfile.value!.createdAt,
            bankDetails: restaurantProfile.value!.bankDetails,
          );
          restaurantProfile.refresh(); // Notify listeners
        }
        Get.snackbar('Success', 'Logo uploaded successfully.');
        if (kDebugMode) {
          print("Logo uploaded for $restaurantUid: $downloadUrl");
        }
      }
    } catch (e) {
      Get.snackbar('Upload Failed', 'Could not upload logo: $e');
      if (kDebugMode) {
        print("Error uploading logo for $restaurantUid: $e");
      }
    } finally {
      isLoadingUpload.value = false;
    }
  }

  // Method to update bank details in Firestore
  Future<void> updateBankDetails(String bankDetails) async {
    if (restaurantUid.isEmpty) return;

    final RxBool isUpdatingBank = true.obs;
    try {
      // Update Firestore
      await _firestore.collection('restaurants').doc(restaurantUid).update({
        'bankDetails': bankDetails,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      if (restaurantProfile.value != null) {
        restaurantProfile.value = RestaurantProfileModel(
          uid: restaurantProfile.value!.uid,
          name: restaurantProfile.value!.name,
          address: restaurantProfile.value!.address,
          logoUrl: restaurantProfile.value!.logoUrl,
          subscriptionPlan: restaurantProfile.value!.subscriptionPlan,
          subscriptionStatus: restaurantProfile.value!.subscriptionStatus,
          currentScanCount: restaurantProfile.value!.currentScanCount,
          trialStartDate: restaurantProfile.value!.trialStartDate,
          createdAt: restaurantProfile.value!.createdAt,
          bankDetails: bankDetails, // Update bank details
        );
        restaurantProfile.refresh(); // Notify listeners
      }

      Get.snackbar('Success', 'Bank details updated successfully');
      if (kDebugMode) {
        print("Bank details updated for $restaurantUid");
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update bank details: $e');
      if (kDebugMode) {
        print("Error updating bank details for $restaurantUid: $e");
      }
    } finally {
      isUpdatingBank.value = false;
    }
  }

  Future<void> processQrScan(String customerUid) async {
    if (restaurantUid.isEmpty) {
      Get.closeAllSnackbars(); // Close any existing snackbars
      Get.snackbar('Error', 'Restaurant user not identified.');
      return;
    }
    if (customerUid.isEmpty) {
      Get.closeAllSnackbars(); // Close any existing snackbars
      Get.snackbar('Scan Error', 'Invalid QR code data.');
      return;
    }

    isLoadingScan.value = true;
    try {
      // 1. Check Restaurateur's Subscription Status
      await fetchRestaurantProfile(); // Ensure latest profile data
      final profile = restaurantProfile.value;
      if (profile == null || !profile.isSubscriptionActive) {
        final message = profile?.subscriptionStatus == 'inactive'
            ? 'Subscription expired. Please renew.'
            : 'Subscription required to scan.';
        Get.closeAllSnackbars(); // Close any existing snackbars
        Get.snackbar('Subscription Issue', message);
        return;
      }

      // 2. Validate Customer UID
      final customerDoc =
          await _firestore.collection('users').doc(customerUid).get();
      if (!customerDoc.exists || customerDoc.data()?['role'] != 'customer') {
        Get.closeAllSnackbars(); // Close any existing snackbars
        Get.snackbar(
          'Invalid QR',
          'This QR code is not linked to a valid customer.',
        );
        return;
      }

      // NEW: Check if the customer already has 10 or more points but hasn't claimed their reward
      final customerPointsMapCheck =
          customerDoc.data()?['pointsByRestaurant'] as Map<String, dynamic>? ??
              {};
      final restaurantPointsDataCheck =
          customerPointsMapCheck[restaurantUid] as Map<String, dynamic>? ??
              {'points': 0, 'rewardReceived': false};

      final customerCurrentPoints =
          restaurantPointsDataCheck['points'] as int? ?? 0;
      final rewardReceived =
          restaurantPointsDataCheck['rewardReceived'] as bool? ?? false;

      // If customer already has 10+ points but hasn't claimed the reward, prevent scanning
      if (customerCurrentPoints >= 10 && !rewardReceived) {
        Get.closeAllSnackbars(); // Close any existing snackbars
        Get.snackbar(
          colorText: MColors.error,
          'Reward Ready',
          'Customer has a pending reward to claim. Please claim your previous reward before scanning again.',
          duration: const Duration(seconds: 5),
          backgroundColor: MColors.white.withOpacity(0.8),
          margin: EdgeInsets.fromLTRB(0, 70, 0, 0),
        );
        return;
      }

      // 3. Check 10-Minute Cooldown for this specific customer
      final now = DateTime.now();
      final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

      final recentScans = await _firestore
          .collection('scans')
          .where('restaurantId', isEqualTo: restaurantUid)
          .where('clientId', isEqualTo: customerUid)
          .where(
            'timestamp',
            isGreaterThan: Timestamp.fromDate(tenMinutesAgo),
          )
          .limit(1) // We only need to know if at least one exists
          .get();

      // --- If all checks pass, proceed with scan ---

      // Use a transaction to ensure atomicity of updates
      WriteBatch batch = _firestore.batch();

      // a. Create Scan Record
      final scanRef = _firestore.collection('scans').doc(); // Auto-generate ID
      batch.set(scanRef, {
        'clientId': customerUid,
        'restaurantId': restaurantUid,
        'timestamp': FieldValue.serverTimestamp(), // Use server time
        'pointsAwarded': 1, // Award 1 point per scan
      });

      // b. Update Customer Points
      final customerRef = _firestore.collection('users').doc(customerUid);
      // Construct the field path for the specific restaurant within the map
      final pointsFieldPath = 'pointsByRestaurant.$restaurantUid.points';
      final rewardReceivedFieldPath =
          'pointsByRestaurant.$restaurantUid.rewardReceived';
      // Increment the points for this restaurant. If the field doesn't exist, Firestore creates it.
      // Note: Firestore doesn't directly support incrementing nested map fields if the map or sub-map doesn't exist.
      // A transaction or reading first might be more robust here if the structure isn't guaranteed.
      // Let's assume 'pointsByRestaurant' map exists, but the restaurant entry might not.
      // Using update with FieldValue.increment is safer. We'll handle initialization if needed.

      // Read current points to handle initialization and reward logic.
      final currentCustomerData = await customerRef.get();
      final customerPointsMap = currentCustomerData
              .data()?['pointsByRestaurant'] as Map<String, dynamic>? ??
          {};
      final restaurantPointsData =
          customerPointsMap[restaurantUid] as Map<String, dynamic>? ??
              {'points': 0, 'rewardReceived': false}; // Default if new
      final currentPoints = restaurantPointsData['points'] as int;
      // final rewardReceived = restaurantPointsData['rewardReceived'] as bool; // Not needed for increment

      // We'll just increment the points count. Reward logic might be handled client-side or server-side later.
      // If pointsByRestaurant.restaurantUid doesn't exist, update won't create nested structure correctly.
      // We'll update the whole map field for safety.
      customerPointsMap[restaurantUid] = {
        'points': currentPoints + 1,
        // Keep existing reward status or default to false
        'rewardReceived': restaurantPointsData['rewardReceived'],
        // Add lastUpdated timestamp to track when points were last updated
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      batch.update(customerRef, {'pointsByRestaurant': customerPointsMap});

      // c. Update Restaurant's Scan Count
      final restaurantRef =
          _firestore.collection('restaurants').doc(restaurantUid);
      batch.update(restaurantRef, {
        'currentScanCount': FieldValue.increment(1),
      });

      // Commit the transaction
      await batch.commit();

      // Update local state after successful transaction
      await fetchRestaurantProfile(); // Re-fetch to get updated scan count

      Get.closeAllSnackbars(); // Close any existing snackbars
      Get.snackbar('Success', 'Customer scan recorded. +1 point awarded.');
      if (kDebugMode) {
        print(
          "Scan successful: Customer $customerUid at Restaurant $restaurantUid",
        );
      }
    } catch (e) {
      Get.closeAllSnackbars(); // Close any existing snackbars
      Get.snackbar('Scan Error', 'An unexpected error occurred: $e');
      if (kDebugMode) {
        print("Error processing scan for $customerUid at $restaurantUid: $e");
      }
    } finally {
      isLoadingScan.value = false;
    }
  }

  // Fetch claimed rewards history for the restaurant
  Future<void> fetchClaimedRewards() async {
    if (restaurantUid.isEmpty) return;

    isLoadingClaims.value = true;
    claimedRewards.clear(); // Clear before fetching new data

    try {
      // Keep a reference to the Firestore instance
      final firestore = FirebaseFirestore.instance;

      final snapshot = await firestore
          .collection('claims')
          .where('restaurantId', isEqualTo: restaurantUid)
          .orderBy('claimDate', descending: true)
          .get(GetOptions(
              source: Source.serverAndCache)); // Try server first, then cache

      if (snapshot.docs.isNotEmpty) {
        final rewards = snapshot.docs.map((doc) {
          final data = doc.data();
          return ClaimModel(
            id: doc.id,
            customerId: data['customerId'] ?? '',
            restaurantId: data['restaurantId'] ?? '',
            restaurantName: data['restaurantName'] ?? '',
            rewardType: data['rewardType'] ?? 'Unknown Reward',
            claimDate: (data['claimDate'] as Timestamp).toDate(),
            pointsUsed: data['pointsUsed'] ?? 0,
            isVerified: data['isVerified'] ?? false,
            verifiedDate: data['verifiedDate'] != null
                ? (data['verifiedDate'] as Timestamp).toDate()
                : null,
          );
        }).toList();

        // Use assignAll to trigger reactive updates
        claimedRewards.assignAll(rewards);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch claimed rewards: $e');
      if (kDebugMode) {
        print("Error fetching claimed rewards: $e");
      }
    } finally {
      isLoadingClaims.value = false;
      // Force update in case Obx doesn't catch the changes
      update();
    }
  }

  // Verify a reward claim using the 6-digit code
  Future<bool> verifyRewardClaim(String verificationCode) async {
    if (restaurantUid.isEmpty) return false;

    isVerifying.value = true;
    showVerificationResult.value = true;
    verificationResult.value = '';

    try {
      // Normalize the code (uppercase)
      final normalizedCode = verificationCode.trim().toUpperCase();

      if (normalizedCode.length != 6) {
        verificationResult.value =
            'Invalid code format. Please enter a 6-digit code.';
        return false;
      }

      // Query Firestore for claims with this prefix in the ID
      final querySnapshot = await _firestore.collection('claims').get();

      // Find claims matching this code (checking first 6 characters of ID)
      final matchingClaims = querySnapshot.docs.where((doc) =>
          doc.id.substring(0, 6).toUpperCase() == normalizedCode &&
          doc.data()['restaurantId'] == restaurantUid);

      if (matchingClaims.isEmpty) {
        verificationResult.value =
            'No matching claim found. Please check the code.';
        return false;
      }

      final claimDoc = matchingClaims.first;
      final claimData = claimDoc.data();

      // Check if already verified
      if (claimData['isVerified'] == true) {
        verificationResult.value =
            'This reward has already been verified on ${DateFormat('MMM d, yyyy').format((claimData['verifiedDate'] as Timestamp).toDate())}';
        return false;
      }

      // Mark as verified
      await _firestore.collection('claims').doc(claimDoc.id).update({
        'isVerified': true,
        'verifiedDate': FieldValue.serverTimestamp(),
      });

      // Show success message with reward details
      final rewardType = claimData['rewardType'] ?? 'Reward';
      final customerName = claimData['customerName'] ?? 'Customer';

      verificationResult.value =
          'Success! Verified "$rewardType" reward. This claim is now marked as fulfilled.';

      // Refresh the claims list
      await fetchClaimedRewards();

      return true;
    } catch (e) {
      verificationResult.value =
          'Error: Failed to verify claim. ${e.toString()}';
      if (kDebugMode) {
        print("Error verifying claim: $e");
      }
      return false;
    } finally {
      isVerifying.value = false;
    }
  }

  // Clear verification result
  void clearVerificationResult() {
    showVerificationResult.value = false;
    verificationResult.value = '';
  }

  // Fetch the latest scans for this restaurant (with customer name and date)
  Future<void> fetchRecentScans() async {
    if (restaurantUid.isEmpty) return;
    try {
      final querySnapshot = await _firestore
          .collection('scans')
          .where('restaurantId', isEqualTo: restaurantUid)
          .orderBy('timestamp', descending: true)
          .get();
      final List<Map<String, String>> scans = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final customerId = data['clientId'] as String?;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        String customerName = 'Customer';
        if (customerId != null) {
          final customerDoc =
              await _firestore.collection('users').doc(customerId).get();
          if (customerDoc.exists) {
            customerName = customerDoc.data()?['name'] ?? 'Customer';
          }
        }
        final dateStr =
            timestamp != null ? DateFormat('MMM d').format(timestamp) : '';
        scans.add({'name': customerName, 'date': dateStr});
      }
      recentScans.assignAll(scans);
    } catch (e) {
      if (kDebugMode) print('Error fetching recent scans: $e');
      recentScans.clear();
    }
  }

  // Fetch scan counts per day for the current month for the chart
  Future<void> fetchScanChartData() async {
    if (restaurantUid.isEmpty) return;
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final querySnapshot = await _firestore
          .collection('scans')
          .where('restaurantId', isEqualTo: restaurantUid)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .orderBy('timestamp')
          .get();
      // Count scans per day
      final Map<int, int> dayToCount = {};
      for (var doc in querySnapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final day = timestamp.day;
          dayToCount[day] = (dayToCount[day] ?? 0) + 1;
        }
      }

      // Build cumulative total
      final List<FlSpot> spots = [];
      int runningTotal = 0;
      final days = dayToCount.keys.toList()..sort();
      for (final day in days) {
        runningTotal += dayToCount[day]!;
        spots.add(FlSpot(day.toDouble(), runningTotal.toDouble()));
      }
      scanChartData.assignAll(spots);
    } catch (e) {
      if (kDebugMode) print('Error fetching scan chart data: $e');
      scanChartData.clear();
    }
  }

  // After a scan is recorded, also refresh dashboard data
  Future<void> recordScanAndRefresh(String customerUid) async {
    await processQrScan(customerUid);
    await fetchRecentScans();
    await fetchScanChartData();
  }

  // Stream of recent scans for live updates with minimal data for faster loading
  Stream<List<Map<String, dynamic>>> recentScansStream() {
    if (restaurantUid.isEmpty) return const Stream.empty();
    
    return _firestore
        .collection('scans')
        .where('restaurantId', isEqualTo: restaurantUid)
        .orderBy('timestamp', descending: true)
        .limit(20) // Limit to just 20 most recent scans for much faster loading
        .snapshots()
        .map((snapshot) {
          // Using .map instead of .asyncMap for faster processing (no async customer data fetching)
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'name': 'Customer', // Skip customer name lookup for faster loading
              'date': (data['timestamp'] as Timestamp?)?.toDate(),
              'points': data['pointsAwarded'] ?? 1,
            };
          }).toList();
        });
  }
}
