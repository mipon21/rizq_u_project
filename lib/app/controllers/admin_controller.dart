import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:rizq/app/routes/app_pages.dart';

class AdminController extends GetxController {
  static AdminController get instance => Get.find();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for login form
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool hidePassword = true.obs;

  // Dashboard metrics
  final RxInt totalRestaurants = 0.obs;
  final RxInt totalCustomers = 0.obs;
  final RxDouble totalRevenue = 0.0.obs;
  final RxInt newRestaurantsThisMonth = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Check if user is already logged in as admin
    checkAdminAuth();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Toggle password visibility
  void togglePasswordVisibility() => hidePassword.value = !hidePassword.value;

  // Check if current user is an admin
  Future<bool> checkAdminAuth() async {
    final user = _auth.currentUser;
    if (user != null) {
      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();
      return adminDoc.exists;
    }
    return false;
  }

  // Admin login function
  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter both email and password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Attempt to sign in
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Check if user is an admin
      final adminDoc = await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .get();
      if (!adminDoc.exists) {
        await _auth.signOut();
        throw 'Access denied: Not an admin account';
      }

      if (kDebugMode) {
        print('Admin login successful: ${userCredential.user!.email}');
        print('Attempting to navigate to: ${Routes.ADMIN_DASHBOARD}');
      }

      // Force navigation by clearing middleware temporarily
      await Future.delayed(const Duration(milliseconds: 100));
      Get.offAllNamed(Routes.ADMIN_DASHBOARD);

      // If that doesn't work, try this alternative approach:
      // Get.off(() => const AdminDashboardPage(), binding: AdminBinding());
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No admin found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else {
        message = e.message ?? 'Authentication failed';
      }
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch dashboard metrics
  Future<void> fetchDashboardMetrics() async {
    try {
      // Get total restaurants
      final restaurantsSnapshot =
          await _firestore.collection('restaurants').get();
      totalRestaurants.value = restaurantsSnapshot.docs.length;

      // Get total customers
      final customersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();
      totalCustomers.value = customersSnapshot.docs.length;

      // Get new restaurants this month
      final DateTime firstDayOfMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      );
      final newRestaurantsSnapshot = await _firestore
          .collection('restaurants')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .get();
      newRestaurantsThisMonth.value = newRestaurantsSnapshot.docs.length;

      // Calculate total revenue
      double revenue = 0.0;
      final subscriptionsSnapshot =
          await _firestore.collection('subscriptions').get();
      for (var doc in subscriptionsSnapshot.docs) {
        revenue += (doc.data()['amountPaid'] as num? ?? 0).toDouble();
      }
      totalRevenue.value = revenue;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching dashboard metrics: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to load dashboard data',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Logout function
  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAllNamed(Routes.ADMIN_LOGIN);
    } catch (e) {
      if (kDebugMode) {
        print('Error logging out: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to logout',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
