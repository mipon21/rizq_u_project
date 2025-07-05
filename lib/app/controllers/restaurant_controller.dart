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
  final String subscriptionPlan; // e.g., 'free_trial', custom plan ID
  final String subscriptionStatus; // e.g., 'active', 'inactive', 'free_trial'
  final int currentScanCount;
  final DateTime? trialStartDate;
  final DateTime createdAt;
  final String bankDetails; // New field for bank details
  final DateTime? subscriptionEnd; // New field for subscription end date
  final bool isSuspended; // New field for suspension status
  // Registration fields
  final String? ownerName;
  final String? supportEmail;
  final String? ibanNumber;
  final String? ownerNationalIdFront;
  final String? ownerNationalIdBack;

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
    this.subscriptionEnd, // New parameter
    this.isSuspended = false, // Default to not suspended
    this.ownerName,
    this.supportEmail,
    this.ibanNumber,
    this.ownerNationalIdFront,
    this.ownerNationalIdBack,
  });

  factory RestaurantProfileModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    
    // Get scan count with proper type checking
    int scanCount = 0;
    try {
      final rawScanCount = data['currentScanCount'];
      if (rawScanCount is int) {
        scanCount = rawScanCount;
      } else if (rawScanCount is num) {
        scanCount = rawScanCount.toInt();
      } else if (rawScanCount is String) {
        scanCount = int.tryParse(rawScanCount) ?? 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing scan count: $e');
        print('Raw scan count value: ${data['currentScanCount']}');
      }
    }

    return RestaurantProfileModel(
      uid: data['uid'] ?? snapshot.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      subscriptionPlan: data['subscriptionPlan'] ?? 'free_trial',
      subscriptionStatus: data['subscriptionStatus'] ?? 'inactive',
      currentScanCount: scanCount,
      trialStartDate: (data['trialStartDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bankDetails: data['bankDetails'] ?? '',
      subscriptionEnd: (data['subscriptionEnd'] as Timestamp?)?.toDate(),
      isSuspended: data['isSuspended'] ?? false,
      ownerName: data['ownerName'],
      supportEmail: data['supportEmail'],
      ibanNumber: data['ibanNumber'],
      ownerNationalIdFront: data['ownerNationalIdFront'],
      ownerNationalIdBack: data['ownerNationalIdBack'],
    );
  }

  // Create a copy of this model with updated scan count
  RestaurantProfileModel copyWith({int? currentScanCount}) {
    return RestaurantProfileModel(
      uid: uid,
      name: name,
      address: address,
      logoUrl: logoUrl,
      subscriptionPlan: subscriptionPlan,
      subscriptionStatus: subscriptionStatus,
      currentScanCount: currentScanCount ?? this.currentScanCount,
      trialStartDate: trialStartDate,
      createdAt: createdAt,
      bankDetails: bankDetails,
      subscriptionEnd: subscriptionEnd,
      isSuspended: isSuspended,
      ownerName: ownerName,
      supportEmail: supportEmail,
      ibanNumber: ibanNumber,
      ownerNationalIdFront: ownerNationalIdFront,
      ownerNationalIdBack: ownerNationalIdBack,
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
    // Check if trial period (30 days) is still valid
    return DateTime.now().difference(trialStartDate!).inDays <= 30;
  }

  // Example: Get remaining trial days
  int get remainingTrialDays {
    if (!isTrialActive || trialStartDate == null) return 0;
    final expiryDate = trialStartDate!.add(const Duration(days: 30));
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  // Get remaining subscription days
  int get remainingSubscriptionDays {
    if (subscriptionEnd == null) return 0;
    final remaining = subscriptionEnd!.difference(DateTime.now()).inDays;
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
  final RxInt currentMonthScanCount = 0.obs;

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
  bool get isSuspended => restaurantProfile.value?.isSuspended ?? false;
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
    currentMonthScanCount.value = 0;

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
    
    isLoadingProfile.value = true;
    try {
      final doc = await _firestore
          .collection('restaurants')
          .doc(restaurantUid)
          .get(const GetOptions(source: Source.server)); // Force server fetch
      
      if (doc.exists) {
        restaurantProfile.value = RestaurantProfileModel.fromSnapshot(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );
        if (kDebugMode) {
          print(
              "Successfully loaded profile for ${restaurantProfile.value?.name}");
          print(
              "Current scan count: ${restaurantProfile.value?.currentScanCount}");
        }
      } else {
        restaurantProfile.value = null;
        if (kDebugMode) print("No restaurant profile found for $restaurantUid");
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching restaurant profile: $e");
    } finally {
      isLoadingProfile.value = false;
    }
    return restaurantProfile.value != null;
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
            subscriptionEnd: restaurantProfile.value!.subscriptionEnd,
            ownerName: restaurantProfile.value!.ownerName,
            supportEmail: restaurantProfile.value!.supportEmail,
            ibanNumber: restaurantProfile.value!.ibanNumber,
            ownerNationalIdFront: restaurantProfile.value!.ownerNationalIdFront,
            ownerNationalIdBack: restaurantProfile.value!.ownerNationalIdBack,
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

  Future<void> processQrScan(String customerUid) async {
    if (restaurantUid.isEmpty) {
      Get.closeAllSnackbars();
      Get.snackbar('Error', 'Restaurant user not identified.');
      return;
    }
    if (customerUid.isEmpty) {
      Get.closeAllSnackbars();
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
        Get.closeAllSnackbars();
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

      // Check if customer has scanned within the last 10 minutes
      if (recentScans.docs.isNotEmpty) {
        final lastScanTime =
            (recentScans.docs.first.data()['timestamp'] as Timestamp).toDate();
        final timeDifference = now.difference(lastScanTime).inMinutes;
        final remainingMinutes = 10 - timeDifference;

        Get.closeAllSnackbars();
        Get.snackbar(
          colorText: MColors.error,
          'Cooldown Active',
          'This customer can scan again in $remainingMinutes minute${remainingMinutes != 1 ? 's' : ''}.',
          duration: const Duration(seconds: 5),
          backgroundColor: MColors.white.withOpacity(0.8),
          margin: EdgeInsets.fromLTRB(0, 70, 0, 0),
        );
        return;
      }

      // --- If all checks pass, proceed with scan ---

      // Use a transaction to ensure atomicity of updates
      await _firestore.runTransaction((transaction) async {
        // Get the current restaurant data
        final restaurantDoc = await transaction
            .get(_firestore.collection('restaurants').doc(restaurantUid));

        if (!restaurantDoc.exists) {
          throw Exception('Restaurant document not found');
        }

        // Get current scan count
        final currentScanCount = restaurantDoc.data()?['currentScanCount'] ?? 0;

        // Create scan record
        final scanRef = _firestore.collection('scans').doc();
        transaction.set(scanRef, {
          'clientId': customerUid,
          'restaurantId': restaurantUid,
          'timestamp': FieldValue.serverTimestamp(),
          'pointsAwarded': 1,
        });

        // Update customer points
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
        transaction
            .update(customerRef, {'pointsByRestaurant': customerPointsMap});

        // Update restaurant scan count
        transaction
            .update(_firestore.collection('restaurants').doc(restaurantUid), {
          'currentScanCount': currentScanCount + 1,
          'lastScanTime': FieldValue.serverTimestamp(),
        });

        // Update local state immediately
        if (restaurantProfile.value != null) {
          // Use copyWith to create a new profile with updated scan count
          restaurantProfile.value = restaurantProfile.value!
              .copyWith(currentScanCount: currentScanCount + 1);
          if (kDebugMode) {
            print(
                "Updated local scan count: ${restaurantProfile.value?.currentScanCount}");
          }
        }
      });

      // Refresh dashboard data
      await refreshDashboardData();

      Get.closeAllSnackbars();
      Get.snackbar('Success', 'Customer scan recorded. +1 point awarded.');
      
      if (kDebugMode) {
        print(
            "Scan successful: Customer $customerUid at Restaurant $restaurantUid");
        print("Final scan count: ${restaurantProfile.value?.currentScanCount}");
      }
      
    } catch (e) {
      Get.closeAllSnackbars();
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

  // Fetch scan counts per day for the subscription period for the chart
  Future<void> fetchScanChartData() async {
    if (restaurantUid.isEmpty) return;
    try {
      final profile = restaurantProfile.value;
      if (profile == null) {
        if (kDebugMode) print('fetchScanChartData: Profile is null');
        return;
      }

      // Get subscription period dates
      final periodStart = profile.trialStartDate ?? profile.createdAt;
      final periodEnd = profile.subscriptionEnd ??
          DateTime.now().add(const Duration(days: 30));

      // Get subscription start date - this is when the current plan was assigned
      // Use this to only show scans that occurred after the subscription was changed
      final subscriptionStartDate = await _getSubscriptionStartDate();
      final effectiveStartDate = subscriptionStartDate ?? periodStart;

      if (kDebugMode) {
        print('fetchScanChartData: Period Start: $periodStart');
        print('fetchScanChartData: Subscription Start: $subscriptionStartDate');
        print('fetchScanChartData: Effective Start: $effectiveStartDate');
        print('fetchScanChartData: Period End: $periodEnd');
      }

      if (effectiveStartDate == null) {
        if (kDebugMode) print('fetchScanChartData: Missing period start date');
        scanChartData.clear();
        currentMonthScanCount.value = 0;
        return;
      }

      if (kDebugMode) print('fetchScanChartData: Querying scans...');

      // Query all scans for this restaurant within the period
      final querySnapshot = await _firestore
          .collection('scans')
          .where('restaurantId', isEqualTo: restaurantUid)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(effectiveStartDate))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
          .orderBy('timestamp')
          .get();
      
      if (kDebugMode) {
        print('fetchScanChartData: Found ${querySnapshot.docs.length} scans');
      }

      // Count scans per day using date string as key
      final Map<String, int> dayToCount = {};
      int totalScans = 0;

      // Initialize all days in the period with 0 scans
      DateTime currentDate = effectiveStartDate;
      while (!currentDate.isAfter(periodEnd)) {
        final dateKey =
            '${currentDate.year}-${currentDate.month}-${currentDate.day}';
        dayToCount[dateKey] = 0;
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      // Count actual scans
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // Skip archived scans
        if (data['archivedAt'] != null) {
          continue;
        }

        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final dateKey =
              '${timestamp.year}-${timestamp.month}-${timestamp.day}';
          dayToCount[dateKey] = (dayToCount[dateKey] ?? 0) + 1;
          totalScans++;
        }
      }

      if (kDebugMode) {
        print('fetchScanChartData: Total scans counted: $totalScans');
        print('fetchScanChartData: Daily counts: $dayToCount');
      }

      // Build daily scan chart data for the entire subscription period
      final List<FlSpot> spots = [];
      
      // Reset currentDate to start of period
      currentDate = effectiveStartDate;
      int dayIndex = 0;

      // Create spots for each day, including days with 0 scans
      while (!currentDate.isAfter(periodEnd)) {
        final dateKey =
            '${currentDate.year}-${currentDate.month}-${currentDate.day}';
        final dailyCount = dayToCount[dateKey] ?? 0;

        if (kDebugMode) {
          print(
              'Chart point: Day ${dayIndex + 1} (${DateFormat('MMM d').format(currentDate)}): $dailyCount scans');
        }
        
        spots.add(FlSpot((dayIndex + 1).toDouble(), dailyCount.toDouble()));
        currentDate = currentDate.add(const Duration(days: 1));
        dayIndex++;
      }
      
      // Update the chart data
      scanChartData.assignAll(spots);
      
      if (kDebugMode) {
        print('Chart data updated with ${spots.length} points');
        print('First point: ${spots.firstOrNull}');
        print('Last point: ${spots.lastOrNull}');
      }
      
    } catch (e) {
      if (kDebugMode) print('Error fetching scan chart data: $e');
      scanChartData.clear();
    }
  }

  // Helper method to get the most recent subscription start date
  Future<DateTime?> _getSubscriptionStartDate() async {
    try {
      // Get the most recent subscription record for this restaurant
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('restaurantId', isEqualTo: restaurantUid)
          .where('status', isEqualTo: 'active')
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (subscriptionsSnapshot.docs.isNotEmpty) {
        final subscriptionData = subscriptionsSnapshot.docs.first.data();
        final startDate = subscriptionData['startDate'] as Timestamp?;
        return startDate?.toDate();
      }

      // If no subscription record found, check the restaurant document
      final restaurantDoc =
          await _firestore.collection('restaurants').doc(restaurantUid).get();

      if (restaurantDoc.exists) {
        final data = restaurantDoc.data();
        if (data != null) {
          final subscriptionStart = data['subscriptionStart'] as Timestamp?;
          if (subscriptionStart != null) {
            return subscriptionStart.toDate();
          }
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting subscription start date: $e');
      return null;
    }
  }

  Future<void> refreshDashboardData() async {
    if (kDebugMode) print('Refreshing dashboard data...');
    try {
      // Fetch profile first to get latest scan count
      await fetchRestaurantProfile();

      // Update scan count based on non-archived scans
      await updateCurrentScanCount();

      // Then fetch other data in parallel
      await Future.wait([
        fetchRecentScans(),
        fetchScanChartData(),
      ]);

      if (kDebugMode) {
        print('Dashboard data refreshed');
        print(
            'Current scan count: ${restaurantProfile.value?.currentScanCount}');
        print('Chart data points: ${scanChartData.length}');
      }
    } catch (e) {
      if (kDebugMode) print('Error refreshing dashboard data: $e');
    }
  }

  // Update the current scan count based on non-archived scans
  Future<void> updateCurrentScanCount() async {
    if (restaurantUid.isEmpty) return;
    try {
      final profile = restaurantProfile.value;
      if (profile == null) return;

      // Get subscription period dates
      final periodStart = profile.trialStartDate ?? profile.createdAt;
      final periodEnd = profile.subscriptionEnd ??
          DateTime.now().add(const Duration(days: 30));

      // Get subscription start date - this is when the current plan was assigned
      final subscriptionStartDate = await _getSubscriptionStartDate();
      final effectiveStartDate = subscriptionStartDate ?? periodStart;

      if (effectiveStartDate == null) return;

      // Count non-archived scans
      final querySnapshot = await _firestore
          .collection('scans')
          .where('restaurantId', isEqualTo: restaurantUid)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(effectiveStartDate))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
          .get();

      int validScanCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // Only count non-archived scans
        if (data['archivedAt'] == null) {
          validScanCount++;
        }
      }

      // Update the restaurant document with the correct scan count
      await _firestore.collection('restaurants').doc(restaurantUid).update({
        'currentScanCount': validScanCount,
        'updatedAt': Timestamp.now(),
      });

      // Update local profile
      if (restaurantProfile.value != null) {
        restaurantProfile.value = restaurantProfile.value!.copyWith(
          currentScanCount: validScanCount,
        );
      }

      if (kDebugMode) {
        print('Updated current scan count to $validScanCount');
      }
    } catch (e) {
      if (kDebugMode) print('Error updating current scan count: $e');
    }
  }

  Future<void> recordScanAndRefresh(String customerUid) async {
    if (kDebugMode) {
      print("Starting scan process for customer: $customerUid");
      print(
          "Current scan count before: ${restaurantProfile.value?.currentScanCount}");
    }
    
    await processQrScan(customerUid);
    await updateCurrentScanCount(); // Update scan count based on non-archived scans
    await refreshDashboardData();

    if (kDebugMode) {
      print("Dashboard data refreshed after scan");
      print("New scan count: ${restaurantProfile.value?.currentScanCount}");
      print("Chart data points: ${scanChartData.length}");
      print("Last chart point: ${scanChartData.lastOrNull}");
    }
  }

  // Stream of recent scans for live updates with customer names
  Stream<List<Map<String, dynamic>>> recentScansStream() {
    if (restaurantUid.isEmpty) return const Stream.empty();

    return _firestore
        .collection('scans')
        .where('restaurantId', isEqualTo: restaurantUid)
        .orderBy('timestamp', descending: true)
        .limit(20) // Limit to just 20 most recent scans
        .snapshots()
        .asyncMap((snapshot) async {
      // Using asyncMap to fetch customer names from users collection
      final List<Map<String, dynamic>> scans = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final customerId = data['clientId'] as String?;
        String customerName = 'Customer';
        
        // Fetch customer name from users collection
        if (customerId != null) {
          try {
            final customerDoc = await _firestore.collection('users').doc(customerId).get();
            if (customerDoc.exists) {
              customerName = customerDoc.data()?['name'] ?? 'Customer';
            }
          } catch (e) {
            // If customer lookup fails, keep default name
            customerName = 'Customer';
          }
        }
        
        scans.add({
          'name': customerName, // Show actual customer name
          'date': (data['timestamp'] as Timestamp?)?.toDate(),
          'points': data['pointsAwarded'] ?? 1,
        });
      }
      
      return scans;
    });
  }
}
