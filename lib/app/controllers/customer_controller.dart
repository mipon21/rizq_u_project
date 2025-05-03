import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust import path
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart'; // For Material Design
import 'package:image_picker/image_picker.dart';
import 'package:rizq/app/routes/app_pages.dart';
import 'package:rizq/app/ui/pages/customer/scan_history_page.dart';

// Represents the data needed for a loyalty card display
class LoyaltyCardModel {
  final String restaurantId;
  final String restaurantName;
  final String logoUrl;
  final int points;
  final int pointsRequired; // e.g., 10
  final String rewardType; // e.g., "Free Coffee"
  final bool rewardReady; // Calculated: points >= pointsRequired
  final int actualPoints; // Store actual points for backend operations

  LoyaltyCardModel({
    required this.restaurantId,
    required this.restaurantName,
    required this.logoUrl,
    required this.points,
    required this.pointsRequired,
    required this.rewardType,
    int? actualPoints,
  })  : actualPoints = actualPoints ?? points,
        rewardReady = points >= pointsRequired;
}

// Represents a restaurant's loyalty program to be displayed to all customers
class RestaurantProgramModel {
  final String restaurantId;
  final String restaurantName;
  final String logoUrl;
  final String rewardType;
  final int pointsRequired;
  final int customerPoints;
  final int actualPoints; // Store actual points for backend operations
  final bool rewardReady;

  RestaurantProgramModel({
    required this.restaurantId,
    required this.restaurantName,
    required this.logoUrl,
    required this.rewardType,
    required this.pointsRequired,
    this.customerPoints = 0,
    int? actualPoints, // Optional parameter that defaults to customerPoints
  })  : actualPoints = actualPoints ?? customerPoints,
        rewardReady = customerPoints >= pointsRequired;
}

// Represents a single entry in the scan history
class ScanHistoryItemModel {
  final String id;
  final String restaurantName;
  final DateTime timestamp;
  final int pointsAwarded;

  ScanHistoryItemModel({
    required this.id,
    required this.restaurantName,
    required this.timestamp,
    required this.pointsAwarded,
  });

  // Formatter for display
  String get formattedTimestamp =>
      DateFormat('MMM d, yyyy - hh:mm a').format(timestamp);
}

// Represents a claimed reward in history
class ClaimHistoryItemModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String rewardType;
  final DateTime claimDate;
  final bool isVerified;
  final DateTime? verifiedDate;

  ClaimHistoryItemModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.rewardType,
    required this.claimDate,
    this.isVerified = false,
    this.verifiedDate,
  });

  // Formatter for display
  String get formattedClaimDate =>
      DateFormat('MMM d, yyyy - hh:mm a').format(claimDate);

  String get formattedVerifiedDate => verifiedDate != null
      ? DateFormat('MMM d, yyyy - hh:mm a').format(verifiedDate!)
      : '';
}

// Customer Profile Model
class CustomerProfileModel {
  final String uid;
  final String name;
  final String? photoUrl;
  final String email;
  final String? phoneNumber;
  final DateTime createdAt;
  final String? address;

  CustomerProfileModel({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.email,
    this.phoneNumber,
    required this.createdAt,
    this.address,
  });

  factory CustomerProfileModel.fromMap(Map<String, dynamic> data, String uid) {
    return CustomerProfileModel(
      uid: uid,
      name: data['name'] ?? 'Customer',
      photoUrl: data['photoUrl'],
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: data['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      // We don't update createdAt or uid as they should remain constant
    };
  }

  // Create a copy with modified fields
  CustomerProfileModel copyWith({
    String? name,
    String? photoUrl,
    String? phoneNumber,
    String? address,
  }) {
    return CustomerProfileModel(
      uid: this.uid,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      email: this.email, // Email can't be changed
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: this.createdAt,
      address: address ?? this.address,
    );
  }
}

class CustomerController extends GetxController {
  static CustomerController get instance => Get.find();
  final AuthController _authController =
      Get.find(); // Get AuthController instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoadingLoyalty = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool isLoadingPrograms = false.obs;
  final RxBool isClaimingReward = false.obs;

  final RxList<LoyaltyCardModel> loyaltyCards = <LoyaltyCardModel>[].obs;
  final RxList<ScanHistoryItemModel> scanHistory = <ScanHistoryItemModel>[].obs;
  final RxList<RestaurantProgramModel> allPrograms =
      <RestaurantProgramModel>[].obs;
  final RxList<ClaimHistoryItemModel> claimHistory =
      <ClaimHistoryItemModel>[].obs;

  // Profile related properties
  final Rx<CustomerProfileModel?> customerProfile =
      Rx<CustomerProfileModel?>(null);
  final RxBool isLoadingProfile = false.obs;
  final RxBool isUpdatingProfile = false.obs;
  final RxBool isUploadingImage = false.obs;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get userUid => _authController.currentUserUid;

  @override
  void onInit() {
    super.onInit();
    // Fetch data when the controller is initialized, if user is logged in
    if (userUid.isNotEmpty) {
      _initializeData();
    }

    // Listen to auth changes using the public getter
    ever(_authController.reactiveFirebaseUser, (User? user) {
      if (user != null) {
        // Check if user is not null (logged in)
        _initializeData();
      } else {
        // Clear data if user logs out
        _clearData();
      }
    });
  }

  // Initialize all data with error handling for each call
  Future<void> _initializeData() async {
    try {
      await fetchLoyaltyData().catchError((e) {
        if (kDebugMode) {
          print("Error fetching loyalty data: $e");
        }
      });

      await fetchScanHistory().catchError((e) {
        if (kDebugMode) {
          print("Error fetching scan history: $e");
        }
      });

      await fetchAllRestaurantPrograms().catchError((e) {
        if (kDebugMode) {
          print("Error fetching restaurant programs: $e");
        }
      });

      await fetchClaimHistory().catchError((e) {
        if (kDebugMode) {
          print("Error fetching claim history: $e");
        }
      });

      await fetchCustomerProfile().catchError((e) {
        if (kDebugMode) {
          print("Error fetching customer profile: $e");
        }
      });

      checkForRewardsReadyToClaim();
    } catch (e) {
      if (kDebugMode) {
        print("Error during data initialization: $e");
      }
    }
  }

  // Clear all data
  void _clearData() {
    loyaltyCards.clear();
    scanHistory.clear();
    allPrograms.clear();
    claimHistory.clear();
    customerProfile.value = null;
    if (kDebugMode) {
      print("Auth state changed: User logged out. Clearing customer data.");
    }
  }

  // Combined fetch function
  Future<void> fetchAllCustomerData() async {
    await Future.wait([
      fetchLoyaltyData(),
      fetchScanHistory(),
      fetchAllRestaurantPrograms(),
      fetchClaimHistory(),
      fetchCustomerProfile(),
    ]);
    checkForRewardsReadyToClaim();
  }

  // Fetch all restaurant programs to display to the customer
  Future<void> fetchAllRestaurantPrograms() async {
    if (userUid.isEmpty) return;
    isLoadingPrograms.value = true;
    try {
      // Get all programs from Firestore with error handling and timeouts
      final programsSnapshot = await _firestore
          .collection('programs')
          .get()
          .timeout(const Duration(seconds: 15),
              onTimeout: () => throw Exception(
                  'Connection timeout. Please check your network.'));

      // Get customer's points from their profile with better error handling
      Map<String, dynamic> pointsByRestaurant = {};
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(userUid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (userDoc.exists &&
            (userDoc.data() != null) &&
            userDoc.data()!.containsKey('pointsByRestaurant')) {
          pointsByRestaurant =
              userDoc.data()!['pointsByRestaurant'] as Map<String, dynamic>;
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching user points: $e");
        }
        // Continue with empty points rather than failing the whole function
      }

      final List<RestaurantProgramModel> programs = [];
      bool hasRewardReadyToastShown = false;

      // Process each program with individual error handling
      for (var programDoc in programsSnapshot.docs) {
        try {
          final programData = programDoc.data();
          final restaurantId = programDoc.id;

          // Get restaurant details
          final restaurantDoc = await _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .get();
          if (!restaurantDoc.exists || restaurantDoc.data() == null)
            continue; // Skip if restaurant doesn't exist

          final restaurantData = restaurantDoc.data()!;

          // Get customer's points for this restaurant
          int customerPoints = 0;
          if (pointsByRestaurant.containsKey(restaurantId)) {
            final restaurantPoints =
                pointsByRestaurant[restaurantId] as Map<String, dynamic>? ?? {};
            customerPoints = restaurantPoints['points'] as int? ?? 0;

            // Check if customer has enough points and show a notification to claim reward
            final pointsRequired = programData['pointsRequired'] ?? 10;
            if (customerPoints >= pointsRequired && !hasRewardReadyToastShown) {
              hasRewardReadyToastShown = true;
              Get.snackbar(
                'Reward Ready!',
                'You\'ve reached enough points for ${restaurantData['name']}! Claim your reward.',
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.purple[100],
                colorText: Colors.purple[900],
                snackPosition: SnackPosition.TOP,
              );
            }
          }

          // Get the points required for this program
          final pointsRequired = programData['pointsRequired'] ?? 10;

          // Cap displayed points at the required amount for visual clarity
          final displayPoints = customerPoints >= pointsRequired
              ? pointsRequired
              : customerPoints;

          programs.add(RestaurantProgramModel(
            restaurantId: restaurantId,
            restaurantName: restaurantData['name'] ?? 'Unknown Restaurant',
            logoUrl: restaurantData['logoUrl'] ?? '',
            rewardType: programData['rewardType'] ?? 'Free Item',
            pointsRequired: pointsRequired,
            customerPoints: displayPoints,
            actualPoints: customerPoints,
          ));
        } catch (e) {
          // Log error but continue processing other programs
          if (kDebugMode) {
            print("Error processing program ${programDoc.id}: $e");
          }
        }
      }

      // Update the observable list safely
      allPrograms.value = programs;

      if (kDebugMode) {
        print("Fetched ${programs.length} restaurant programs");
      }
    } catch (e) {
      // Show user-friendly error message
      Get.snackbar(
        'Data Loading Error',
        'Unable to load restaurant programs. Please try again later.',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );

      if (kDebugMode) {
        print("Error fetching restaurant programs: $e");
      }

      // Ensure we're not showing a loading indicator if there's an error
      isLoadingPrograms.value = false;
    } finally {
      // Always ensure loading state is reset
      isLoadingPrograms.value = false;
    }
  }

  // Claim a reward when customer has enough points
  Future<void> claimReward(RestaurantProgramModel program) async {
    if (userUid.isEmpty) return;
    if (!program.rewardReady) {
      Get.snackbar('Not Eligible', 'You need more points to claim this reward');
      return;
    }

    isClaimingReward.value = true;

    try {
      // Start a batch write operation for atomicity
      final batch = _firestore.batch();

      // 1. Reset the customer's points for this restaurant
      final userRef = _firestore.collection('users').doc(userUid);
      final pointsPath = 'pointsByRestaurant.${program.restaurantId}';

      // Get current user data to update
      final userDoc = await userRef.get();
      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('User document not found');
      }

      Map<String, dynamic> userData = userDoc.data()!;
      if (!userData.containsKey('pointsByRestaurant')) {
        userData['pointsByRestaurant'] = {};
      }

      Map<String, dynamic> pointsByRestaurant =
          userData['pointsByRestaurant'] as Map<String, dynamic>;

      // Reset points to 0
      if (!pointsByRestaurant.containsKey(program.restaurantId)) {
        pointsByRestaurant[program.restaurantId] = {
          'points': 0,
          'rewardReceived': false
        };
      } else {
        pointsByRestaurant[program.restaurantId] = {
          'points': 0,
          'rewardReceived': false
        };
      }

      batch.update(userRef, {'pointsByRestaurant': pointsByRestaurant});

      // 2. Create a claim record in the claims collection
      final claimRef = _firestore.collection('claims').doc();
      final String claimId = claimRef.id;

      batch.set(claimRef, {
        'customerId': userUid,
        'restaurantId': program.restaurantId,
        'restaurantName': program.restaurantName,
        'rewardType': program.rewardType,
        'claimDate': FieldValue.serverTimestamp(),
        'pointsUsed': program.actualPoints > 0
            ? program.actualPoints
            : program.customerPoints,
      });

      // 3. Update restaurant stats (optional)
      final restaurantRef =
          _firestore.collection('restaurants').doc(program.restaurantId);
      batch.update(restaurantRef, {
        'totalRewardsClaimed': FieldValue.increment(1),
      });

      // Commit the batch
      await batch.commit();

      // Show beautiful reward claimed dialog instead of a simple snackbar
      // This should be shown BEFORE refreshing data to prevent navigation
      await _showRewardClaimedDialog(program, claimId);

      // Refresh data AFTER the dialog is dismissed to prevent navigation issues
      await fetchAllCustomerData();
    } catch (e) {
      Get.snackbar('Error', 'Failed to claim reward: $e');
      if (kDebugMode) {
        print("Error claiming reward: $e");
      }
    } finally {
      isClaimingReward.value = false;
    }
  }

  // Show a beautiful dialog when reward is claimed
  Future<void> _showRewardClaimedDialog(
      RestaurantProgramModel program, String claimId) async {
    final String verificationCode = claimId.substring(0, 6).toUpperCase();

    // Return a Future that completes when the dialog is dismissed
    return await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple[700]!,
                Colors.purple[900]!,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Congratulations icon
              Container(
                width: 80,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.celebration,
                  size: 50,
                  color: Colors.purple[800],
                ),
              ),
              const SizedBox(height: 10),

              // Congratulations text
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // Claimed reward details
              Text(
                'You\'ve claimed:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                program.rewardType + "!",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Restaurant name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  program.restaurantName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),

              // Verification code
              const Text(
                'SHOW THIS CODE TO THE RESTAURANT',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Text(
                  verificationCode,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[900],
                    letterSpacing: 5,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Important instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'This reward must be verified by restaurant staff to redeem.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              // // Close button
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: () => Get.back(),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.white,
              //       foregroundColor: Colors.purple[900],
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(10),
              //       ),
              //     ),
              //     child: const Text(
              //       'DONE',
              //       style: TextStyle(
              //         fontWeight: FontWeight.bold,
              //         fontSize: 16,
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Take a Screenshot or Press the Button Below to go to your Reward History',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(Get.context!).pop(); // Close the dialog
                    Get.toNamed(Routes.CUSTOMER_SCAN_HISTORY);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple[900],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Go to Reward History',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Fetch claim history
  Future<void> fetchClaimHistory() async {
    if (userUid.isEmpty) return;

    try {
      final querySnapshot = await _firestore
          .collection('claims')
          .where('customerId', isEqualTo: userUid)
          .orderBy('claimDate', descending: true)
          .limit(20)
          .get();

      final List<ClaimHistoryItemModel> claims = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp =
            (data['claimDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final verifiedDate = (data['verifiedDate'] as Timestamp?)?.toDate();

        claims.add(ClaimHistoryItemModel(
          id: doc.id,
          restaurantId: data['restaurantId'] ?? '',
          restaurantName: data['restaurantName'] ?? 'Unknown Restaurant',
          rewardType: data['rewardType'] ?? 'Reward',
          claimDate: timestamp,
          isVerified: data['isVerified'] ?? false,
          verifiedDate: verifiedDate,
        ));
      }

      claimHistory.assignAll(claims);
      if (kDebugMode) {
        print("Fetched ${claims.length} claim history items");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching claim history: $e");
      }
    }
  }

  Future<void> fetchLoyaltyData() async {
    if (userUid.isEmpty) return;
    isLoadingLoyalty.value = true;
    try {
      final userDoc = await _firestore.collection('users').doc(userUid).get();
      if (!userDoc.exists ||
          !(userDoc.data()?.containsKey('pointsByRestaurant') ?? false)) {
        loyaltyCards.clear(); // Clear if no points data exists
        return;
      }

      final Map<String, dynamic> pointsData =
          userDoc.data()!['pointsByRestaurant'];
      final List<LoyaltyCardModel> cards = [];

      // Fetch details for each restaurant the user has points with
      for (var entry in pointsData.entries) {
        final restaurantId = entry.key;
        final pointsInfo = entry.value
            as Map<String, dynamic>; // { points: 7, rewardReceived: false }

        final restaurantDoc =
            await _firestore.collection('restaurants').doc(restaurantId).get();
        final programDoc =
            await _firestore.collection('programs').doc(restaurantId).get();

        if (restaurantDoc.exists && programDoc.exists) {
          final restaurantData = restaurantDoc.data()!;
          final programData = programDoc.data()!;

          // Get points and required points
          final actualPoints = pointsInfo['points'] ?? 0;
          final pointsRequired = programData['pointsRequired'] ?? 10;

          // Cap displayed points at the required amount for visual clarity
          final displayPoints =
              actualPoints >= pointsRequired ? pointsRequired : actualPoints;

          cards.add(LoyaltyCardModel(
            restaurantId: restaurantId,
            restaurantName: restaurantData['name'] ?? 'Unknown Restaurant',
            logoUrl: restaurantData['logoUrl'] ?? '',
            points: displayPoints,
            // rewardReceived: pointsInfo['rewardReceived'] ?? false, // Not directly used in model, rewardReady calculates
            pointsRequired: pointsRequired, // Default to 10 if not set
            rewardType: programData['rewardType'] ?? 'Free Item',
            actualPoints: actualPoints,
          ));
        } else {
          if (kDebugMode) {
            print(
                "Warning: Restaurant ($restaurantId) or Program data missing for customer $userUid");
          }
        }
      }
      loyaltyCards.assignAll(cards);
      if (kDebugMode) {
        print("Fetched ${cards.length} loyalty cards for customer $userUid");
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch loyalty points: $e');
      if (kDebugMode) {
        print("Error fetching loyalty data for $userUid: $e");
      }
    } finally {
      isLoadingLoyalty.value = false;
    }
  }

  Future<void> fetchScanHistory() async {
    if (userUid.isEmpty) return;
    isLoadingHistory.value = true;
    try {
      final querySnapshot = await _firestore
          .collection('scans')
          .where('clientId', isEqualTo: userUid)
          .orderBy('timestamp', descending: true)
          .orderBy('__name__', descending: true)
          .limit(50) // Limit history length for performance
          .get();

      final List<ScanHistoryItemModel> history = [];

      // Need to fetch restaurant names for each scan
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final restaurantId = data['restaurantId'] as String?;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        final points =
            data['pointsAwarded'] as int? ?? 1; // Default to 1 point if missing

        if (restaurantId == null || timestamp == null) {
          if (kDebugMode) {
            print(
                "Warning: Scan record ${doc.id} is missing restaurantId or timestamp.");
          }
          continue; // Skip incomplete records
        }

        // Optimize: Cache restaurant names if fetching many scans for same restaurants
        final restaurantDoc =
            await _firestore.collection('restaurants').doc(restaurantId).get();
        final restaurantName = restaurantDoc.exists
            ? restaurantDoc.data() != null
                ? restaurantDoc.data()!['name']
                : 'Unknown Restaurant'
            : 'Unknown Restaurant';

        history.add(ScanHistoryItemModel(
          id: doc.id,
          restaurantName: restaurantName,
          timestamp: timestamp,
          pointsAwarded: points,
        ));
      }
      scanHistory.assignAll(history);
      if (kDebugMode) {
        print(
            "Fetched ${history.length} scan history items for customer $userUid");
      }
    } catch (e) {
      String errorMessage = 'Failed to fetch scan history';

      // Check if it's an index error
      if (e.toString().contains('The query requires an index')) {
        // Extract the URL from the error message
        final urlStart = e.toString().indexOf('https://');
        final urlEnd = e.toString().indexOf(' ', urlStart);
        final indexUrl = urlStart != -1 && urlEnd != -1
            ? e
                .toString()
                .substring(urlStart, urlEnd > 0 ? urlEnd : e.toString().length)
            : '';

        Get.snackbar('Index Required',
            'The app needs a database index to be created. Please contact the administrator.',
            duration: const Duration(seconds: 7),
            snackPosition: SnackPosition.BOTTOM);

        if (kDebugMode) {
          print("Error fetching scan history for $userUid: $e");
          if (indexUrl.isNotEmpty) {
            print("Create the index at: $indexUrl");
          }
        }
      } else {
        Get.snackbar('Error', '$errorMessage: $e');
        if (kDebugMode) {
          print("Error fetching scan history for $userUid: $e");
        }
      }
    } finally {
      isLoadingHistory.value = false;
    }
  }

  // Fetch customer profile data
  Future<void> fetchCustomerProfile() async {
    if (userUid.isEmpty) return;

    isLoadingProfile.value = true;

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userUid).get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        // If profile doesn't exist, create a basic one from auth data
        User? currentUser = _authController.reactiveFirebaseUser.value;
        if (currentUser != null) {
          final newProfile = CustomerProfileModel(
            uid: userUid,
            name: currentUser.displayName ?? 'Customer',
            email: currentUser.email ?? '',
            photoUrl: currentUser.photoURL,
            createdAt: DateTime.now(),
          );

          // Save this basic profile
          await _firestore.collection('users').doc(userUid).set({
            'name': newProfile.name,
            'email': newProfile.email,
            'photoUrl': newProfile.photoUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'customer',
          }, SetOptions(merge: true));

          customerProfile.value = newProfile;
        } else {
          // No auth user data, can't create a profile
          customerProfile.value = null;
        }
      } else {
        // Use existing data from Firestore
        final data = docSnapshot.data()!;
        customerProfile.value = CustomerProfileModel.fromMap(data, userUid);
      }

      if (kDebugMode) {
        print("Fetched profile for customer $userUid");
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load profile: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (kDebugMode) {
        print("Error fetching customer profile: $e");
      }
    } finally {
      isLoadingProfile.value = false;
    }
  }

  // Update profile information
  Future<bool> updateProfile({
    required String name,
    String? phoneNumber,
    String? address,
  }) async {
    if (userUid.isEmpty || customerProfile.value == null) return false;

    isUpdatingProfile.value = true;

    try {
      // Update local model first
      customerProfile.value = customerProfile.value!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        address: address,
      );

      // Update in Firestore
      await _firestore.collection('users').doc(userUid).update({
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
      });

      // Update display name in Firebase Auth if changed
      User? currentUser = _authController.reactiveFirebaseUser.value;
      if (currentUser != null && currentUser.displayName != name) {
        await currentUser.updateDisplayName(name);
      }

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      if (kDebugMode) {
        print("Error updating customer profile: $e");
      }
      return false;
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage() async {
    if (userUid.isEmpty) return false;

    isUploadingImage.value = true;

    try {
      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) {
        // User canceled image picking
        return false;
      }

      // Upload to Firebase Storage
      final File imageFile = File(image.path);
      final String fileName =
          '$userUid-profile-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
          _storage.ref().child('profile_images/$fileName');

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update profile with new photo URL
      if (customerProfile.value != null) {
        customerProfile.value = customerProfile.value!.copyWith(
          photoUrl: downloadUrl,
        );
      }

      // Update Firestore document
      await _firestore.collection('users').doc(userUid).update({
        'photoUrl': downloadUrl,
      });

      // Update Firebase Auth photoURL
      User? currentUser = _authController.reactiveFirebaseUser.value;
      if (currentUser != null) {
        await currentUser.updatePhotoURL(downloadUrl);
      }

      Get.snackbar(
        'Success',
        'Profile picture updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      if (kDebugMode) {
        print("Error uploading profile image: $e");
      }
      return false;
    } finally {
      isUploadingImage.value = false;
    }
  }

  // Check if customer has any rewards ready to claim
  Future<void> checkForRewardsReadyToClaim() async {
    if (userUid.isEmpty) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userUid).get();
      if (!userDoc.exists || userDoc.data() == null) return;

      final pointsByRestaurant =
          userDoc.data()!['pointsByRestaurant'] as Map<String, dynamic>? ?? {};
      List<String> rewardsReadyRestaurants = [];

      for (var entry in pointsByRestaurant.entries) {
        final restaurantId = entry.key;
        final pointsData = entry.value as Map<String, dynamic>;
        final points = pointsData['points'] as int? ?? 0;

        if (points >= 10) {
          // Get restaurant name
          final restaurantDoc = await _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .get();
          if (restaurantDoc.exists && restaurantDoc.data() != null) {
            final restaurantName =
                restaurantDoc.data()!['name'] ?? 'Unknown Restaurant';
            rewardsReadyRestaurants.add(restaurantName);
          }

          // Only get the first restaurant with a ready reward to avoid overwhelming the user
          if (rewardsReadyRestaurants.isNotEmpty) break;
        }
      }

      if (rewardsReadyRestaurants.isNotEmpty) {
        Get.snackbar(
          'Claim Your Reward!',
          'You have a reward ready to claim at ${rewardsReadyRestaurants.first}. Claim it to continue earning points!',
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.purple[100],
          colorText: Colors.purple[900],
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(10),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error checking for rewards ready to claim: $e");
      }
    }
  }
}
