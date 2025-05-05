import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';

class AdminMiddleware extends GetMiddleware {
  @override
  int? get priority => 9;

  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
    try {
      final isAdmin = await _isAdmin();

      if (kDebugMode) {
        print(
            'AdminMiddleware checking auth: $isAdmin for route: ${route.currentPage?.name}');
      }

      final currentRoute = route.currentPage?.name;

      // If user is not an admin and trying to access admin routes (except login),
      // redirect to admin login
      if (!isAdmin &&
          currentRoute != Routes.ADMIN_LOGIN &&
          currentRoute != null &&
          currentRoute.startsWith('/admin')) {
        return GetNavConfig.fromRoute(Routes.ADMIN_LOGIN);
      }

      // If user is an admin and trying to access admin login, redirect to admin dashboard
      if (isAdmin && currentRoute == Routes.ADMIN_LOGIN) {
        return GetNavConfig.fromRoute(Routes.ADMIN_DASHBOARD);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in AdminMiddleware: $e');
      }

      final currentRoute = route.currentPage?.name;
      // If there's an error, redirect to admin login for safety
      if (currentRoute != Routes.ADMIN_LOGIN &&
          currentRoute != null &&
          currentRoute.startsWith('/admin')) {
        return GetNavConfig.fromRoute(Routes.ADMIN_LOGIN);
      }
      return null;
    }
  }

  Future<bool> _isAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) print('Middleware check: No user logged in');
        return false;
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (kDebugMode) {
        print('Middleware admin check for UID ${user.uid}: ${adminDoc.exists}');
      }

      return adminDoc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking admin status: $e');
      }
      return false;
    }
  }
}
