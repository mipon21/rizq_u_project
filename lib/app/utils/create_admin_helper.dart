import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CreateAdminHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates an admin document for the current user
  /// Call this method once to set up your admin access
  static Future<void> createAdminDocument({
    String? customEmail,
    String? customName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently logged in';
      }

      final adminData = {
        'uid': user.uid,
        'email': customEmail ?? user.email ?? '',
        'name': customName ?? 'Admin User',
        'role': 'super_admin',
        'permissions': [
          'manage_restaurants',
          'manage_customers',
          'manage_subscriptions',
          'view_reports',
          'manage_admins',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('admins').doc(user.uid).set(adminData);
      
      if (kDebugMode) {
        print('Admin document created successfully for: ${user.email}');
        print('Admin UID: ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating admin document: $e');
      }
      rethrow;
    }
  }

  /// Checks if current user has admin access
  static Future<bool> checkAdminAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      return adminDoc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking admin access: $e');
      }
      return false;
    }
  }
} 