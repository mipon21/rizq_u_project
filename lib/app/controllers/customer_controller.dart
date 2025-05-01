import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust import path
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter/foundation.dart'; // For kDebugMode

// Represents the data needed for a loyalty card display
class LoyaltyCardModel {
  final String restaurantId;
  final String restaurantName;
  final String logoUrl;
  final int points;
  final int pointsRequired; // e.g., 10
  final String rewardType; // e.g., "Free Coffee"
  final bool rewardReady; // Calculated: points >= pointsRequired

  LoyaltyCardModel({
    required this.restaurantId,
    required this.restaurantName,
    required this.logoUrl,
    required this.points,
    required this.pointsRequired,
    required this.rewardType,
  }) : rewardReady = points >= pointsRequired;
}

// Represents a restaurant's loyalty program to be displayed to all customers
class RestaurantProgramModel {
  final String restaurantId;
  final String restaurantName;
  final String logoUrl;
  final String rewardType;
  final int pointsRequired;
  final int customerPoints;
  final bool rewardReady;

  RestaurantProgramModel({
    required this.restaurantId,
    required this.restaurantName,
    required this.logoUrl,
    required this.rewardType,
    required this.pointsRequired,
    this.customerPoints = 0,
  }) : rewardReady = customerPoints >= pointsRequired;
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

class CustomerController extends GetxController {
  static CustomerController get instance => Get.find();
  final AuthController _authController =
      Get.find(); // Get AuthController instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoadingLoyalty = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool isLoadingPrograms = false.obs;

  final RxList<LoyaltyCardModel> loyaltyCards = <LoyaltyCardModel>[].obs;
  final RxList<ScanHistoryItemModel> scanHistory = <ScanHistoryItemModel>[].obs;
  final RxList<RestaurantProgramModel> allPrograms =
      <RestaurantProgramModel>[].obs;

  String get userUid => _authController.currentUserUid;

  @override
  void onInit() {
    super.onInit();
    // Fetch data when the controller is initialized, if user is logged in
    if (userUid.isNotEmpty) {
      fetchLoyaltyData();
      fetchScanHistory();
      fetchAllRestaurantPrograms();
    }
    // Listen to auth changes using the NEW public getter
    ever(_authController.reactiveFirebaseUser, (User? user) {
      // Pass the user to the callback
      if (user != null) {
        // Check if user is not null (logged in)
        fetchLoyaltyData();
        fetchScanHistory();
        fetchAllRestaurantPrograms();
      } else {
        // Clear data if user logs out
        loyaltyCards.clear();
        scanHistory.clear();
        allPrograms.clear();
        if (kDebugMode) {
          print("Auth state changed: User logged out. Clearing customer data.");
        }
      }
    });
  }

  // Combined fetch function
  Future<void> fetchAllCustomerData() async {
    await Future.wait([
      fetchLoyaltyData(),
      fetchScanHistory(),
      fetchAllRestaurantPrograms(),
    ]);
  }

  // Fetch all restaurant programs to display to the customer
  Future<void> fetchAllRestaurantPrograms() async {
    if (userUid.isEmpty) return;
    isLoadingPrograms.value = true;
    try {
      // Get all programs from Firestore
      final programsSnapshot = await _firestore.collection('programs').get();

      // Get customer's points from their profile
      final userDoc = await _firestore.collection('users').doc(userUid).get();
      Map<String, dynamic> pointsByRestaurant = {};

      if (userDoc.exists &&
          (userDoc.data() != null) &&
          userDoc.data()!.containsKey('pointsByRestaurant')) {
        pointsByRestaurant =
            userDoc.data()!['pointsByRestaurant'] as Map<String, dynamic>;
      }

      final List<RestaurantProgramModel> programs = [];

      // Process each program
      for (var programDoc in programsSnapshot.docs) {
        final programData = programDoc.data();
        final restaurantId = programDoc.id;

        // Get restaurant details
        final restaurantDoc =
            await _firestore.collection('restaurants').doc(restaurantId).get();
        if (!restaurantDoc.exists) continue; // Skip if restaurant doesn't exist

        final restaurantData = restaurantDoc.data()!;

        // Get customer's points for this restaurant
        int customerPoints = 0;
        if (pointsByRestaurant.containsKey(restaurantId)) {
          final restaurantPoints =
              pointsByRestaurant[restaurantId] as Map<String, dynamic>;
          customerPoints = restaurantPoints['points'] as int? ?? 0;
        }

        programs.add(RestaurantProgramModel(
          restaurantId: restaurantId,
          restaurantName: restaurantData['name'] ?? 'Unknown Restaurant',
          logoUrl: restaurantData['logoUrl'] ?? '',
          rewardType: programData['rewardType'] ?? 'Free Item',
          pointsRequired: programData['pointsRequired'] ?? 10,
          customerPoints: customerPoints,
        ));
      }

      allPrograms.assignAll(programs);
      if (kDebugMode) {
        print("Fetched ${programs.length} restaurant programs");
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch restaurant programs: $e');
      if (kDebugMode) {
        print("Error fetching restaurant programs: $e");
      }
    } finally {
      isLoadingPrograms.value = false;
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

          cards.add(LoyaltyCardModel(
            restaurantId: restaurantId,
            restaurantName: restaurantData['name'] ?? 'Unknown Restaurant',
            logoUrl: restaurantData['logoUrl'] ?? '',
            points: pointsInfo['points'] ?? 0,
            // rewardReceived: pointsInfo['rewardReceived'] ?? false, // Not directly used in model, rewardReady calculates
            pointsRequired:
                programData['pointsRequired'] ?? 10, // Default to 10 if not set
            rewardType: programData['rewardType'] ?? 'Free Item',
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
}
