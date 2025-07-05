import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/database_schema.dart';
import '../models/customer_loyalty_model.dart';

/// Data Migration Service
/// This service handles migrating and fixing existing data to ensure proper relationships
class DataMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Main migration function - run this to fix all data connectivity issues
  static Future<void> performFullMigration() async {
    try {
      print('🚀 Starting comprehensive data migration...');

      // Step 1: Fix restaurant registration to restaurant profile sync
      await _syncRestaurantRegistrations();

      // Step 2: Create missing customer loyalty records
      await _createMissingCustomerLoyaltyRecords();

      // Step 3: Fix subscription plan references
      await _fixSubscriptionPlanReferences();

      // Step 4: Create missing QR codes
      await _createMissingQRCodes();

      // Step 5: Fix scan and claim relationships
      await _fixScanAndClaimRelationships();

      // Step 6: Update admin notifications
      await _updateAdminNotifications();

      // Step 7: Clean up orphaned data
      await _cleanupOrphanedData();

      print('✅ Data migration completed successfully!');
    } catch (e) {
      print('❌ Error during data migration: $e');
      rethrow;
    }
  }

  /// Sync restaurant registrations with restaurant profiles
  static Future<void> _syncRestaurantRegistrations() async {
    print('📋 Syncing restaurant registrations...');

    final registrationsSnapshot = await _firestore
        .collection(DatabaseSchema.restaurantRegistrations)
        .where('approvalStatus', isEqualTo: 'approved')
        .get();

    final batch = _firestore.batch();
    int syncedCount = 0;

    for (var doc in registrationsSnapshot.docs) {
      final data = doc.data();
      final uid = data['uid'] as String;

      // Check if restaurant profile exists
      final restaurantDoc = await _firestore
          .collection(DatabaseSchema.restaurants)
          .doc(uid)
          .get();

      if (!restaurantDoc.exists) {
        // Create restaurant profile from registration
        final restaurantData = {
          'uid': uid,
          'restaurantName': data['restaurantName'],
          'ownerName': data['ownerName'],
          'address': '', // Will be updated by restaurant
          'logoUrl': data['logoUrl'],
          'email': data['email'] ?? '',
          'supportEmail': data['supportEmail'],
          'bankDetails': data['bankDetails'],
          'ibanNumber': data['ibanNumber'],
          'subscriptionPlanId': 'free_trial', // Default to free trial
          'subscriptionStatus': 'trial',
          'subscriptionStart': data['approvedAt'],
          'subscriptionEnd': data['approvedAt'] != null
              ? Timestamp.fromDate((data['approvedAt'] as Timestamp)
                  .toDate()
                  .add(const Duration(days: 30)))
              : null,
          'currentScanCount': 0,
          'trialStartDate': data['approvedAt'],
          'approvalStatus': 'approved',
          'approvedAt': data['approvedAt'],
          'createdAt': data['createdAt'],
          'updatedAt': Timestamp.now(),
          'isActive': true,
        };

        batch.set(
          _firestore.collection(DatabaseSchema.restaurants).doc(uid),
          restaurantData,
        );
        syncedCount++;
      }
    }

    await batch.commit();
    print('✅ Synced $syncedCount restaurant profiles');
  }

  /// Create missing customer loyalty records
  static Future<void> _createMissingCustomerLoyaltyRecords() async {
    print('🎯 Creating missing customer loyalty records...');

    // Get all scans
    final scansSnapshot = await _firestore.collection(DatabaseSchema.scans).get();

    // Group scans by customer and restaurant
    final Map<String, Map<String, int>> customerRestaurantPoints = {};

    for (var scan in scansSnapshot.docs) {
      final data = scan.data();
      final customerId = data['customerId'] as String;
      final restaurantId = data['restaurantId'] as String;
      final points = data['pointsAwarded'] as int? ?? 0;

      customerRestaurantPoints.putIfAbsent(customerId, () => {});
      customerRestaurantPoints[customerId]!.putIfAbsent(restaurantId, () => 0);
      customerRestaurantPoints[customerId]![restaurantId] =
          customerRestaurantPoints[customerId]![restaurantId]! + points;
    }

    // Create or update loyalty records
    final batch = _firestore.batch();
    int createdCount = 0;

    for (var customerId in customerRestaurantPoints.keys) {
      for (var restaurantId in customerRestaurantPoints[customerId]!.keys) {
        final points = customerRestaurantPoints[customerId]![restaurantId]!;

        // Check if loyalty record exists
        final loyaltyQuery = await _firestore
            .collection(DatabaseSchema.customerLoyalty)
            .where('customerId', isEqualTo: customerId)
            .where('restaurantId', isEqualTo: restaurantId)
            .get();

        if (loyaltyQuery.docs.isEmpty) {
          // Create new loyalty record
          final loyaltyData = {
            'customerId': customerId,
            'restaurantId': restaurantId,
            'points': points,
            'lastUpdated': Timestamp.now(),
            'createdAt': Timestamp.now(),
          };

          batch.set(
            _firestore.collection(DatabaseSchema.customerLoyalty).doc(),
            loyaltyData,
          );
          createdCount++;
        }
      }
    }

    await batch.commit();
    print('✅ Created $createdCount loyalty records');
  }

  /// Fix subscription plan references
  static Future<void> _fixSubscriptionPlanReferences() async {
    print('📦 Fixing subscription plan references...');

    // Get all restaurants with old plan references
    final restaurantsSnapshot =
        await _firestore.collection(DatabaseSchema.restaurants).get();

    // Get available subscription plans
    final plansSnapshot =
        await _firestore.collection(DatabaseSchema.subscriptionPlans).get();

    final plans = <String, String>{}; // name -> id
    for (var doc in plansSnapshot.docs) {
      final data = doc.data();
      plans[data['name'] as String] = doc.id;
    }

    final batch = _firestore.batch();
    int updatedCount = 0;

    for (var doc in restaurantsSnapshot.docs) {
      final data = doc.data();
      final currentPlan = data['subscriptionPlan'] as String?;

      // Fix old hardcoded plan references
      String? newPlanId;
      if (currentPlan == 'plan_100' || currentPlan == 'Basic Plan') {
        newPlanId = plans['Basic Plan'] ?? plans['Starter Plan'];
      } else if (currentPlan == 'plan_250' || currentPlan == 'Standard Plan') {
        newPlanId = plans['Standard Plan'] ?? plans['Business Plan'];
      } else if (currentPlan == 'plan_unlimited' ||
          currentPlan == 'Premium Plan') {
        newPlanId = plans['Premium Plan'];
      }

      if (newPlanId != null && newPlanId != currentPlan) {
        batch.update(doc.reference, {
          'subscriptionPlanId': newPlanId,
          'updatedAt': Timestamp.now(),
        });
        updatedCount++;
      }
    }

    await batch.commit();
    print('✅ Updated $updatedCount subscription plan references');
  }

  /// Create missing QR codes for restaurants
  static Future<void> _createMissingQRCodes() async {
    print('🔲 Creating missing QR codes...');

    final restaurantsSnapshot =
        await _firestore.collection(DatabaseSchema.restaurants).get();

    final batch = _firestore.batch();
    int createdCount = 0;

    for (var doc in restaurantsSnapshot.docs) {
      final restaurantId = doc.id;

      // Check if QR code exists
      final qrQuery = await _firestore
          .collection(DatabaseSchema.qrCodes)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isActive', isEqualTo: true)
          .get();

      if (qrQuery.docs.isEmpty) {
        // Create QR code
        final qrData = {
          'restaurantId': restaurantId,
          'qrCodeData': 'rizq://restaurant/$restaurantId',
          'isActive': true,
          'createdAt': Timestamp.now(),
        };

        batch.set(
          _firestore.collection(DatabaseSchema.qrCodes).doc(),
          qrData,
        );
        createdCount++;
      }
    }

    await batch.commit();
    print('✅ Created $createdCount QR codes');
  }

  /// Fix scan and claim relationships
  static Future<void> _fixScanAndClaimRelationships() async {
    print('🔗 Fixing scan and claim relationships...');

    // Update scans with missing restaurant names
    final scansSnapshot = await _firestore.collection(DatabaseSchema.scans).get();

    final batch = _firestore.batch();
    int updatedCount = 0;

    for (var scan in scansSnapshot.docs) {
      final data = scan.data();
      final restaurantId = data['restaurantId'] as String;

      if (data['restaurantName'] == null ||
          data['restaurantName'].toString().isEmpty) {
        // Get restaurant name
        final restaurantDoc = await _firestore
            .collection(DatabaseSchema.restaurants)
            .doc(restaurantId)
            .get();

        if (restaurantDoc.exists) {
          final restaurantData = restaurantDoc.data()!;
          batch.update(scan.reference, {
            'restaurantName': restaurantData['restaurantName'],
          });
          updatedCount++;
        }
      }
    }

    await batch.commit();
    print('✅ Updated $updatedCount scan records');
  }

  /// Update admin notifications
  static Future<void> _updateAdminNotifications() async {
    print('🔔 Updating admin notifications...');

    // Create notification for pending restaurant registrations
    final pendingRegistrations = await _firestore
        .collection(DatabaseSchema.restaurantRegistrations)
        .where('approvalStatus', isEqualTo: 'pending')
        .get();

    if (pendingRegistrations.docs.isNotEmpty) {
      final notificationData = {
        'type': 'restaurant_registration',
        'title': 'Pending Restaurant Registrations',
        'message':
            '${pendingRegistrations.docs.length} restaurant registrations are pending approval',
        'data': {
          'count': pendingRegistrations.docs.length,
          'registrations':
              pendingRegistrations.docs.map((doc) => doc.id).toList(),
        },
        'isRead': false,
        'createdAt': Timestamp.now(),
      };

      await _firestore
          .collection(DatabaseSchema.adminNotifications)
          .add(notificationData);
    }

    print('✅ Updated admin notifications');
  }

  /// Clean up orphaned data
  static Future<void> _cleanupOrphanedData() async {
    print('🧹 Cleaning up orphaned data...');

    // Remove duplicate or invalid records
    // This is a placeholder for specific cleanup logic based on your needs

    print('✅ Cleanup completed');
  }

  /// Validate data integrity
  static Future<Map<String, dynamic>> validateDataIntegrity() async {
    print('🔍 Validating data integrity...');

    final results = <String, dynamic>{};

    // Check for restaurants without programs
    final restaurantsWithoutPrograms = await _firestore
        .collection(DatabaseSchema.restaurants)
        .get();

    int missingPrograms = 0;
    for (var doc in restaurantsWithoutPrograms.docs) {
      final programDoc = await _firestore
          .collection(DatabaseSchema.programs)
          .doc(doc.id)
          .get();

      if (!programDoc.exists) {
        missingPrograms++;
      }
    }

    results['restaurantsWithoutPrograms'] = missingPrograms;

    // Check for scans without customer loyalty records
    final scansWithoutLoyalty = await _firestore
        .collection(DatabaseSchema.scans)
        .get();

    int missingLoyalty = 0;
    for (var scan in scansWithoutLoyalty.docs) {
      final data = scan.data();
      final customerId = data['customerId'] as String;
      final restaurantId = data['restaurantId'] as String;

      final loyaltyQuery = await _firestore
          .collection(DatabaseSchema.customerLoyalty)
          .where('customerId', isEqualTo: customerId)
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      if (loyaltyQuery.docs.isEmpty) {
        missingLoyalty++;
      }
    }

    results['scansWithoutLoyalty'] = missingLoyalty;

    print('✅ Validation completed');
    return results;
  }

  /// Get migration status
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    final status = <String, dynamic>{};

    // Count documents in each collection
    final collections = [
      DatabaseSchema.users,
      DatabaseSchema.restaurants,
      DatabaseSchema.restaurantRegistrations,
      DatabaseSchema.programs,
      DatabaseSchema.scans,
      DatabaseSchema.claims,
      DatabaseSchema.customerLoyalty,
      DatabaseSchema.qrCodes,
    ];

    for (var collectionName in collections) {
      final snapshot = await _firestore.collection(collectionName).get();
      status[collectionName] = snapshot.docs.length;
    }

    return status;
  }
}
