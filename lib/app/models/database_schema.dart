import 'package:cloud_firestore/cloud_firestore.dart';

/// Database Schema Documentation
/// This file defines the proper Firestore collection structure and relationships
/// for the Rizq Loyalty App

class DatabaseSchema {
  // Collection Names
  static const String users = 'users';
  static const String restaurants = 'restaurants';
  static const String restaurantRegistrations = 'restaurant_registrations';
  static const String programs = 'programs';
  static const String scans = 'scans';
  static const String claims = 'claims';
  static const String subscriptions = 'subscriptions';
  static const String subscriptionPlans = 'custom_subscription_plans';
  static const String admins = 'admins';
  static const String adminNotifications = 'admin_notifications';
  static const String qrCodes = 'qr_codes';
  static const String customerLoyalty = 'customer_loyalty';

  /// User Collection Structure
  /// Document ID: Firebase Auth UID
  static const Map<String, dynamic> userSchema = {
    'uid': 'String (Firebase Auth UID)',
    'email': 'String',
    'name': 'String',
    'role': 'String (customer|restaurateur|admin)',
    'phoneNumber': 'String?',
    'photoUrl': 'String?',
    'dateOfBirth': 'Timestamp?',
    'createdAt': 'Timestamp',
    'updatedAt': 'Timestamp',
    'isActive': 'bool',
    'lastLoginAt': 'Timestamp?',
  };

  /// Restaurant Collection Structure
  /// Document ID: Firebase Auth UID (same as user)
  static const Map<String, dynamic> restaurantSchema = {
    'uid': 'String (Firebase Auth UID)',
    'restaurantName': 'String',
    'ownerName': 'String',
    'address': 'String',
    'logoUrl': 'String',
    'supportEmail': 'String',
    'bankDetails': 'String',
    'ibanNumber': 'String',
    'subscriptionPlanId': 'String (Reference to subscription_plans)',
    'subscriptionStatus': 'String (active|inactive|trial|expired)',
    'subscriptionStartDate': 'Timestamp?',
    'subscriptionEndDate': 'Timestamp?',
    'currentScanCount': 'int',
    'trialStartDate': 'Timestamp?',
    'approvalStatus': 'String (pending|approved|rejected)',
    'rejectionReason': 'String?',
    'approvedAt': 'Timestamp?',
    'rejectedAt': 'Timestamp?',
    'createdAt': 'Timestamp',
    'updatedAt': 'Timestamp',
    'isActive': 'bool',
  };

  /// Restaurant Registration Collection Structure
  /// Document ID: Auto-generated
  static const Map<String, dynamic> restaurantRegistrationSchema = {
    'uid': 'String (Firebase Auth UID)',
    'email': 'String',
    'restaurantName': 'String',
    'ownerName': 'String',
    'ownerNationalIdFront': 'String (URL)',
    'ownerNationalIdBack': 'String (URL)',
    'supportEmail': 'String',
    'bankDetails': 'String',
    'ibanNumber': 'String',
    'logoUrl': 'String (URL)',
    'approvalStatus': 'String (pending|approved|rejected)',
    'rejectionReason': 'String?',
    'approvedAt': 'Timestamp?',
    'rejectedAt': 'Timestamp?',
    'createdAt': 'Timestamp',
    'updatedAt': 'Timestamp',
  };

  /// Program Collection Structure (Loyalty Programs)
  /// Document ID: Restaurant UID
  static const Map<String, dynamic> programSchema = {
    'restaurantId': 'String (Reference to restaurants)',
    'restaurantName': 'String',
    'logoUrl': 'String',
    'rewardType': 'String',
    'pointsRequired': 'int',
    'isActive': 'bool',
    'createdAt': 'Timestamp',
    'updatedAt': 'Timestamp',
  };

  /// Customer Loyalty Collection Structure
  /// Document ID: Auto-generated
  static const Map<String, dynamic> customerLoyaltySchema = {
    'customerId': 'String (Reference to users)',
    'restaurantId': 'String (Reference to restaurants)',
    'points': 'int',
    'lastUpdated': 'Timestamp',
    'createdAt': 'Timestamp',
  };

  /// Scan Collection Structure
  /// Document ID: Auto-generated
  static const Map<String, dynamic> scanSchema = {
    'id': 'String',
    'customerId': 'String (Reference to users)',
    'restaurantId': 'String (Reference to restaurants)',
    'restaurantName': 'String',
    'pointsAwarded': 'int',
    'scanDate': 'Timestamp',
    'qrCodeId': 'String? (Reference to qr_codes)',
  };

  /// Claim Collection Structure
  /// Document ID: Auto-generated
  static const Map<String, dynamic> claimSchema = {
    'id': 'String',
    'customerId': 'String (Reference to users)',
    'restaurantId': 'String (Reference to restaurants)',
    'restaurantName': 'String',
    'rewardType': 'String',
    'pointsUsed': 'int',
    'claimDate': 'Timestamp',
    'isVerified': 'bool',
    'verifiedDate': 'Timestamp?',
    'verificationCode': 'String',
  };

  /// Subscription Collection Structure
  /// Document ID: Auto-generated
  static const Map<String, dynamic> subscriptionSchema = {
    'restaurantId': 'String (Reference to restaurants)',
    'planId': 'String (Reference to custom_subscription_plans)',
    'planName': 'String',
    'startDate': 'Timestamp',
    'endDate': 'Timestamp',
    'status': 'String (active|expired|cancelled)',
    'amount': 'double',
    'currency': 'String',
    'createdAt': 'Timestamp',
    'updatedAt': 'Timestamp',
  };

  /// Subscription Plan Collection Structure
  /// Document ID: Auto-generated
  static const Map<String, dynamic> subscriptionPlanSchema = {
    'name': 'String',
    'description': 'String',
    'scanLimit': 'int (-1 for unlimited)',
    'durationDays': 'int',
    'price': 'double',
    'currency': 'String',
    'isActive': 'bool',
    'features': 'List<String>',
    'createdAt': 'Timestamp',
    'updatedAt': 'Timestamp?',
  };

  /// Admin Collection Structure
  /// Document ID: Firebase Auth UID
  static const Map<String, dynamic> adminSchema = {
    'uid': 'String (Firebase Auth UID)',
    'email': 'String',
    'name': 'String',
    'role': 'String (super_admin|admin)',
    'permissions': 'List<String>',
    'createdAt': 'Timestamp',
    'lastLoginAt': 'Timestamp?',
  };

  /// Admin Notification Collection Structure
  /// Document ID: Auto-generated
  static const Map<String, dynamic> adminNotificationSchema = {
    'type': 'String (restaurant_registration|subscription_expiry|system_alert)',
    'title': 'String',
    'message': 'String',
    'data': 'Map<String, dynamic>',
    'isRead': 'bool',
    'createdAt': 'Timestamp',
  };

  /// QR Code Collection Structure
  /// Document ID: Auto-generated
  static const Map<String, dynamic> qrCodeSchema = {
    'restaurantId': 'String (Reference to restaurants)',
    'qrCodeData': 'String',
    'qrCodeImageUrl': 'String?',
    'isActive': 'bool',
    'createdAt': 'Timestamp',
    'lastUsedAt': 'Timestamp?',
  };

  /// Required Firestore Indexes
  static const List<Map<String, dynamic>> requiredIndexes = [
    // Scans collection indexes
    {
      'collection': 'scans',
      'fields': ['customerId', 'scanDate'],
      'order': 'desc',
    },
    {
      'collection': 'scans',
      'fields': ['restaurantId', 'scanDate'],
      'order': 'desc',
    },
    // Claims collection indexes
    {
      'collection': 'claims',
      'fields': ['customerId', 'claimDate'],
      'order': 'desc',
    },
    {
      'collection': 'claims',
      'fields': ['restaurantId', 'claimDate'],
      'order': 'desc',
    },
    // Customer loyalty indexes
    {
      'collection': 'customer_loyalty',
      'fields': ['customerId', 'restaurantId'],
      'order': 'asc',
    },
    // Restaurant indexes
    {
      'collection': 'restaurants',
      'fields': ['approvalStatus', 'createdAt'],
      'order': 'desc',
    },
    {
      'collection': 'restaurants',
      'fields': ['subscriptionStatus', 'subscriptionEndDate'],
      'order': 'asc',
    },
  ];

  /// Data Validation Rules
  static const Map<String, dynamic> validationRules = {
    'users': {
      'email': 'required|email',
      'name': 'required|min:2',
      'role': 'required|in:customer,restaurateur,admin',
    },
    'restaurants': {
      'restaurantName': 'required|min:2',
      'ownerName': 'required|min:2',
      'subscriptionPlanId': 'required',
      'subscriptionStatus': 'required|in:active,inactive,trial,expired',
    },
    'programs': {
      'restaurantId': 'required',
      'rewardType': 'required',
      'pointsRequired': 'required|min:1',
    },
    'scans': {
      'customerId': 'required',
      'restaurantId': 'required',
      'pointsAwarded': 'required|min:0',
    },
    'claims': {
      'customerId': 'required',
      'restaurantId': 'required',
      'pointsUsed': 'required|min:1',
    },
  };
}

/// Helper class for database operations
class DatabaseHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get collection reference
  static CollectionReference collection(String collectionName) {
    return _firestore.collection(collectionName);
  }

  /// Get document reference
  static DocumentReference document(String collectionName, String documentId) {
    return _firestore.collection(collectionName).doc(documentId);
  }

  /// Batch write operations
  static WriteBatch batch() {
    return _firestore.batch();
  }

  /// Transaction operations
  static Future<T> runTransaction<T>(
      Future<T> Function(Transaction) updateFunction) {
    return _firestore.runTransaction(updateFunction);
  }
}
