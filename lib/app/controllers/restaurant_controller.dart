import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust if needed
import 'package:flutter/foundation.dart'; // For kDebugMode

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

  String get restaurantUid => _authController.currentUserUid;

  // Expose profile details reactively
  String get name => restaurantProfile.value?.name ?? '';
  String get address => restaurantProfile.value?.address ?? '';
  String get logoUrl => restaurantProfile.value?.logoUrl ?? '';
  String get subscriptionStatus =>
      restaurantProfile.value?.subscriptionStatus ?? 'inactive';
  bool get isSubscribed =>
      restaurantProfile.value?.isSubscriptionActive ?? false;
  int get scanCount => restaurantProfile.value?.currentScanCount ?? 0;
  int get rewardsIssuedCount => restaurantProfile.value?.rewardsIssued ?? 0;

  @override
  void onInit() {
    super.onInit();
    if (restaurantUid.isNotEmpty) {
      fetchRestaurantProfile();
    }
    // Re-fetch if user changes using the NEW public getter
    ever(_authController.reactiveFirebaseUser, (User? user) {
      // Pass the user
      if (user != null && _authController.userRole.value == 'restaurateur') {
        // Ensure user is logged in and is a restaurateur
        fetchRestaurantProfile();
        if (kDebugMode) {
          print(
            "Auth state changed: Restaurateur logged in. Fetching profile.",
          );
        }
      } else {
        restaurantProfile.value =
            null; // Clear profile on logout or if role changes
        if (kDebugMode) {
          print(
            "Auth state changed: User logged out or role mismatch. Clearing restaurant profile.",
          );
        }
      }
    });
  }

  Future<void> fetchRestaurantProfile() async {
    if (restaurantUid.isEmpty) return;
    isLoadingProfile.value = true;
    try {
      final doc =
          await _firestore.collection('restaurants').doc(restaurantUid).get();
      if (doc.exists) {
        restaurantProfile.value = RestaurantProfileModel.fromSnapshot(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );
        if (kDebugMode) {
          print(
            "Fetched profile for restaurant $restaurantUid. Status: ${restaurantProfile.value?.subscriptionStatus}",
          );
        }
        // Check and update trial status if expired
        _checkAndUpdateTrialStatus();
      } else {
        restaurantProfile.value = null; // Clear if not found
        if (kDebugMode) {
          print("Restaurant profile not found for UID: $restaurantUid");
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch restaurant profile: $e');
      if (kDebugMode) {
        print("Error fetching restaurant profile $restaurantUid: $e");
      }
    } finally {
      isLoadingProfile.value = false;
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
      Get.snackbar('Error', 'Restaurant user not identified.');
      return;
    }
    if (customerUid.isEmpty) {
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
        Get.snackbar('Subscription Issue', message);
        return;
      }

      // 2. Validate Customer UID
      final customerDoc =
          await _firestore.collection('users').doc(customerUid).get();
      if (!customerDoc.exists || customerDoc.data()?['role'] != 'customer') {
        Get.snackbar(
          'Invalid QR',
          'This QR code is not linked to a valid customer.',
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

      if (recentScans.docs.isNotEmpty) {
        final lastScanTime =
            (recentScans.docs.first.data()['timestamp'] as Timestamp).toDate();
        final minutesPassed = now.difference(lastScanTime).inMinutes;
        final waitTime = 10 - minutesPassed;
        Get.snackbar(
          'Cooldown Active',
          'Customer scanned ${minutesPassed}m ago. Please wait ${waitTime}m.',
        );
        return;
      }

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

      Get.snackbar('Success', 'Customer scan recorded. +1 point awarded.');
      if (kDebugMode) {
        print(
          "Scan successful: Customer $customerUid at Restaurant $restaurantUid",
        );
      }
    } catch (e) {
      Get.snackbar('Scan Error', 'An unexpected error occurred: $e');
      if (kDebugMode) {
        print("Error processing scan for $customerUid at $restaurantUid: $e");
      }
    } finally {
      isLoadingScan.value = false;
    }
  }
}
