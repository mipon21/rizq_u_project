import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/database_schema.dart';

/// Customer Loyalty Model
/// Represents the loyalty relationship between a customer and a restaurant
class CustomerLoyaltyModel {
  final String id;
  final String customerId;
  final String restaurantId;
  final String restaurantName;
  final String logoUrl;
  final int points;
  final int pointsRequired;
  final String rewardType;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final bool rewardReady;

  CustomerLoyaltyModel({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.restaurantName,
    required this.logoUrl,
    required this.points,
    required this.pointsRequired,
    required this.rewardType,
    required this.lastUpdated,
    required this.createdAt,
  }) : rewardReady = points >= pointsRequired;

  factory CustomerLoyaltyModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    Map<String, dynamic>? programData,
    Map<String, dynamic>? restaurantData,
  }) {
    final data = snapshot.data()!;
    return CustomerLoyaltyModel(
      id: snapshot.id,
      customerId: data['customerId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: restaurantData?['restaurantName'] ?? '',
      logoUrl: restaurantData?['logoUrl'] ?? '',
      points: data['points'] ?? 0,
      pointsRequired: programData?['pointsRequired'] ?? 10,
      rewardType: programData?['rewardType'] ?? 'Free Reward',
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'restaurantId': restaurantId,
      'points': points,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get remaining points needed for reward
  int get remainingPoints => pointsRequired - points;

  /// Get progress percentage towards reward
  double get progressPercentage => (points / pointsRequired).clamp(0.0, 1.0);

  /// Check if customer can claim reward
  bool get canClaimReward => points >= pointsRequired;

  /// Get formatted points display
  String get formattedPoints => '$points/$pointsRequired';

  /// Get formatted last updated date
  String get formattedLastUpdated {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

/// Customer Loyalty Service
/// Handles operations related to customer loyalty
class CustomerLoyaltyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get customer loyalty for a specific restaurant
  static Future<CustomerLoyaltyModel?> getCustomerLoyalty(
    String customerId,
    String restaurantId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(DatabaseSchema.customerLoyalty)
          .where('customerId', isEqualTo: customerId)
          .where('restaurantId', isEqualTo: restaurantId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      // Get restaurant and program data
      final restaurantDoc = await _firestore
          .collection(DatabaseSchema.restaurants)
          .doc(restaurantId)
          .get();

      final programDoc = await _firestore
          .collection(DatabaseSchema.programs)
          .doc(restaurantId)
          .get();

      return CustomerLoyaltyModel.fromFirestore(
        querySnapshot.docs.first,
        restaurantData: restaurantDoc.data(),
        programData: programDoc.data(),
      );
    } catch (e) {
      print('Error getting customer loyalty: $e');
      return null;
    }
  }

  /// Get all loyalty records for a customer
  static Future<List<CustomerLoyaltyModel>> getCustomerLoyalties(
    String customerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(DatabaseSchema.customerLoyalty)
          .where('customerId', isEqualTo: customerId)
          .orderBy('lastUpdated', descending: true)
          .get();

      final loyalties = <CustomerLoyaltyModel>[];

      for (var doc in querySnapshot.docs) {
        final restaurantId = doc.data()['restaurantId'] as String;

        // Get restaurant and program data
        final restaurantDoc = await _firestore
            .collection(DatabaseSchema.restaurants)
            .doc(restaurantId)
            .get();

        final programDoc = await _firestore
            .collection(DatabaseSchema.programs)
            .doc(restaurantId)
            .get();

        loyalties.add(CustomerLoyaltyModel.fromFirestore(
          doc,
          restaurantData: restaurantDoc.data(),
          programData: programDoc.data(),
        ));
      }

      return loyalties;
    } catch (e) {
      print('Error getting customer loyalties: $e');
      return [];
    }
  }

  /// Add points to customer loyalty
  static Future<bool> addPoints(
    String customerId,
    String restaurantId,
    int pointsToAdd,
  ) async {
    try {
      final loyalty = await getCustomerLoyalty(customerId, restaurantId);

      if (loyalty != null) {
        // Update existing loyalty record
        await _firestore
            .collection(DatabaseSchema.customerLoyalty)
            .doc(loyalty.id)
            .update({
          'points': loyalty.points + pointsToAdd,
          'lastUpdated': Timestamp.now(),
        });
      } else {
        // Create new loyalty record
        await _firestore.collection(DatabaseSchema.customerLoyalty).add({
          'customerId': customerId,
          'restaurantId': restaurantId,
          'points': pointsToAdd,
          'lastUpdated': Timestamp.now(),
          'createdAt': Timestamp.now(),
        });
      }

      return true;
    } catch (e) {
      print('Error adding points: $e');
      return false;
    }
  }

  /// Deduct points when reward is claimed
  static Future<bool> deductPoints(
    String customerId,
    String restaurantId,
    int pointsToDeduct,
  ) async {
    try {
      final loyalty = await getCustomerLoyalty(customerId, restaurantId);

      if (loyalty != null && loyalty.points >= pointsToDeduct) {
        await _firestore
            .collection(DatabaseSchema.customerLoyalty)
            .doc(loyalty.id)
            .update({
          'points': loyalty.points - pointsToDeduct,
          'lastUpdated': Timestamp.now(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error deducting points: $e');
      return false;
    }
  }

  /// Get loyalty statistics for a restaurant
  static Future<Map<String, dynamic>> getLoyaltyStatistics(
    String restaurantId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(DatabaseSchema.customerLoyalty)
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      final loyalties = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final restaurantDoc = await _firestore
              .collection(DatabaseSchema.restaurants)
              .doc(restaurantId)
              .get();

          final programDoc = await _firestore
              .collection(DatabaseSchema.programs)
              .doc(restaurantId)
              .get();

          return CustomerLoyaltyModel.fromFirestore(
            doc,
            restaurantData: restaurantDoc.data(),
            programData: programDoc.data(),
          );
        }),
      );

      int totalCustomers = loyalties.length;
      int totalPoints =
          loyalties.fold(0, (sum, loyalty) => sum + loyalty.points);
      int activeCustomers = loyalties.where((l) => l.points > 0).length;
      int rewardsReady = loyalties.where((l) => l.rewardReady).length;

      return {
        'totalCustomers': totalCustomers,
        'totalPoints': totalPoints,
        'activeCustomers': activeCustomers,
        'rewardsReady': rewardsReady,
        'averagePoints': totalCustomers > 0 ? totalPoints / totalCustomers : 0,
      };
    } catch (e) {
      print('Error getting loyalty statistics: $e');
      return {};
    }
  }
}
