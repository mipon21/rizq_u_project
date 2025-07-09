import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../routes/app_pages.dart';
import '../utils/constants/app_config.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/subscription_plan_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';

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
  final RxBool isAssigningSubscription = false.obs; // Add this line

  // Dashboard metrics
  final RxInt totalRestaurants = 0.obs;
  final RxInt totalCustomers = 0.obs;
  final RxDouble totalRevenue = 0.0.obs;
  final RxDouble customerPayments = 0.0.obs;
  final RxDouble adminAssignmentValue = 0.0.obs;
  final RxString revenueMode =
      'combined'.obs; // 'customer_only', 'combined', 'admin_value'
  final RxInt newRestaurantsThisMonth = 0.obs;
  final RxInt activeSubscriptions = 0.obs;
  final RxInt pendingApprovals = 0.obs;

  // Custom subscription plans
  final RxList<SubscriptionPlanModel> subscriptionPlans =
      <SubscriptionPlanModel>[].obs;
  final RxBool isLoadingSubscriptionPlans = false.obs;

  // Observable variables for loyalty program data
  final RxList<Map<String, dynamic>> loyaltyPrograms =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> recentClaims =
      <Map<String, dynamic>>[].obs;
  final RxInt totalRewardsClaimed = 0.obs;
  final RxBool isLoadingLoyaltyData = false.obs;
  final RxMap<String, int> topRestaurantsByRewards = <String, int>{}.obs;



  // Admin notifications
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxInt unreadNotifications = 0.obs;

  // Search and filter
  final RxString restaurantSearchQuery = ''.obs;
  final RxString customerSearchQuery = ''.obs;
  final RxString selectedRestaurantFilter = 'all'.obs;
  final RxString selectedCustomerFilter = 'all'.obs;
  final RxString selectedReportType = 'subscriptions'.obs;
  
  // Date range for reports
  final Rx<DateTime> reportStartDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> reportEndDate = DateTime.now().obs;
  
  // Revenue analytics data
  final RxList<Map<String, dynamic>> monthlyRevenueData = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingRevenueData = false.obs;
  
  // Restaurant activity data
  final RxList<Map<String, dynamic>> dailyScanData = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingActivityData = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load subscription plans automatically when controller is initialized
    // This ensures plans are available when accessed from restaurant pages
    loadSubscriptionPlans().then((_) {
      // Create default free trial plan if it doesn't exist
      createDefaultFreeTrialPlan();
    });
    // Load notifications
    loadNotifications();
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

  // Fetch revenue data for analytics
  Future<void> fetchRevenueData() async {
    isLoadingRevenueData.value = true;
    try {
      final startDate = Timestamp.fromDate(reportStartDate.value);
      final endDate = Timestamp.fromDate(reportEndDate.value.add(const Duration(hours: 23, minutes: 59, seconds: 59)));

      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('startDate', isGreaterThanOrEqualTo: startDate)
          .where('startDate', isLessThanOrEqualTo: endDate)
          .where('status', whereIn: ['active', 'expired'])
          .get();

      // Group revenue by month
      Map<String, double> monthlyRevenue = {};
      
      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        final subscriptionDate = (data['startDate'] as Timestamp).toDate();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        
        // Create month key (e.g., "2024-01" for January 2024)
        final monthKey = DateFormat('yyyy-MM').format(subscriptionDate);
        final monthLabel = DateFormat('MMM yyyy').format(subscriptionDate);
        
        monthlyRevenue[monthLabel] = (monthlyRevenue[monthLabel] ?? 0.0) + amount;
      }

      // Convert to list of maps for chart
      monthlyRevenueData.value = monthlyRevenue.entries
          .map((entry) => {
                'month': entry.key,
                'amount': entry.value,
              })
          .toList();

      // Sort by date
      monthlyRevenueData.sort((a, b) {
        final dateA = DateFormat('MMM yyyy').parse(a['month']);
        final dateB = DateFormat('MMM yyyy').parse(b['month']);
        return dateA.compareTo(dateB);
      });

      if (kDebugMode) {
        print('Fetched revenue data: ${monthlyRevenueData.length} months');
        for (var data in monthlyRevenueData) {
          print('${data['month']}: \$${data['amount']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching revenue data: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to fetch revenue data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingRevenueData.value = false;
    }
  }

  // Fetch restaurant activity data (scan data)
  Future<void> fetchRestaurantActivityData() async {
    isLoadingActivityData.value = true;
    try {
      final startDate = Timestamp.fromDate(reportStartDate.value);
      final endDate = Timestamp.fromDate(reportEndDate.value.add(const Duration(hours: 23, minutes: 59, seconds: 59)));

      final scansSnapshot = await _firestore
          .collection('scans')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      // Group scans by day
      Map<String, int> dailyScans = {};
      
      for (var doc in scansSnapshot.docs) {
        final data = doc.data();
        final scanDate = (data['timestamp'] as Timestamp?)?.toDate();
        
        if (scanDate != null) {
          // Create day key (e.g., "Mon", "Tue", etc.)
          final dayKey = DateFormat('EEE').format(scanDate);
          dailyScans[dayKey] = (dailyScans[dayKey] ?? 0) + 1;
        }
      }

      // If we have a short date range, show actual dates instead of day names
      final dateRange = reportEndDate.value.difference(reportStartDate.value).inDays;
      
      if (dateRange <= 7) {
        // Show actual dates for short ranges
        dailyScans.clear();
        for (var doc in scansSnapshot.docs) {
          final data = doc.data();
          final scanDate = (data['timestamp'] as Timestamp?)?.toDate();
          
          if (scanDate != null) {
            final dayKey = DateFormat('MMM dd').format(scanDate);
            dailyScans[dayKey] = (dailyScans[dayKey] ?? 0) + 1;
          }
        }
      }

      // Convert to list of maps for chart
      dailyScanData.value = dailyScans.entries
          .map((entry) => {
                'day': entry.key,
                'count': entry.value,
              })
          .toList();

      // Sort by day order for weekly view, or by date for daily view
      if (dateRange > 7) {
        // Sort by day of week
        final dayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dailyScanData.sort((a, b) {
          final indexA = dayOrder.indexOf(a['day']);
          final indexB = dayOrder.indexOf(b['day']);
          return indexA.compareTo(indexB);
        });
      } else {
        // Sort by date
        dailyScanData.sort((a, b) {
          final dateA = DateFormat('MMM dd').parse(a['day']);
          final dateB = DateFormat('MMM dd').parse(b['day']);
          return dateA.compareTo(dateB);
        });
      }

      if (kDebugMode) {
        print('Fetched activity data: ${dailyScanData.length} days');
        print('Total scans in range: ${scansSnapshot.docs.length}');
        for (var data in dailyScanData) {
          print('${data['day']}: ${data['count']} scans');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching activity data: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to fetch activity data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingActivityData.value = false;
    }
  }

  // Admin login function
  Future<void> login() async {
    if (kDebugMode) {
      print('Admin login attempt for email: ${emailController.text.trim()}');
    }
    
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
        // Sign out immediately if not an admin to prevent auth state listener interference
        await _auth.signOut();
        Get.snackbar(
          'Error',
          'Access denied: Not an admin account',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (kDebugMode) {
        print('Admin login successful: ${userCredential.user!.email}');
        print('Attempting to navigate to: ${Routes.ADMIN_DASHBOARD}');
      }

      // Navigate to admin dashboard
      Get.offAllNamed(Routes.ADMIN_DASHBOARD);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException in admin login: ${e.code} - ${e.message}');
      }
      
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No admin found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts. Please try again later';
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
      if (kDebugMode) {
        print('Unexpected error in admin login: $e');
        print('Error type: ${e.runtimeType}');
      }
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
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
    isLoading.value = true;
    try {
      // Debug: Check current user and admin status
      final currentUser = _auth.currentUser;
      if (kDebugMode) {
        print('Current user: ${currentUser?.uid}');
        print('Current user email: ${currentUser?.email}');
      }
      
      // Check if current user is in admins collection
      if (currentUser != null) {
        final adminDoc = await _firestore.collection('admins').doc(currentUser.uid).get();
        if (kDebugMode) {
          print('Admin document exists: ${adminDoc.exists}');
          if (adminDoc.exists) {
            print('Admin data: ${adminDoc.data()}');
          }
        }
      }

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
      double customerPayments = 0.0;
      double adminAssignments = 0.0;
      
      final subscriptionsSnapshot =
          await _firestore.collection('subscriptions').get();
      
      if (kDebugMode) {
        print('=== REVENUE DEBUG INFO ===');
        print('Total subscription documents: ${subscriptionsSnapshot.docs.length}');
        print('Current revenue mode: ${revenueMode.value}');
      }
      
      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        final amountPaid = (data['amountPaid'] as num? ?? 0).toDouble();
        final planPrice = (data['planPrice'] as num? ?? 0).toDouble();
        final paymentStatus = data['paymentStatus'] as String? ?? 'unknown';
        final status = data['status'] as String? ?? 'unknown';
        final planName = data['planName'] as String? ?? 'Unknown';
        
        if (kDebugMode) {
          print('\nSubscription ${doc.id}:');
          print('- Plan: $planName');
          print('- Amount Paid: $amountPaid');
          print('- Plan Price: $planPrice');
          print('- Payment Status: $paymentStatus');
          print('- Status: $status');
        }
        
        // Separate customer payments from admin assignments
        if (paymentStatus.toLowerCase() == 'admin_assigned' ||
            paymentStatus.toLowerCase() == 'admin_extended') {
          // Admin assignments - use plan price as potential revenue value
          adminAssignments += planPrice;
          if (kDebugMode) {
            print('  → Added to Admin Assignments: $planPrice MAD');
            print('  → Current admin assignments total: $adminAssignments MAD');
          }
        } else if (amountPaid > 0) {
          // Real customer payments
          customerPayments += amountPaid;
          revenue += amountPaid;
          if (kDebugMode) {
            print('  → Added to Customer Payments: $amountPaid MAD');
            print('  → Current customer payments total: $customerPayments MAD');
          }
        } else {
          // Zero payments or unknown
          if (kDebugMode) {
            print('  → Skipped: Zero/Unknown payment');
            print('  → Payment status: $paymentStatus');
            print('  → Plan price: $planPrice MAD');
          }
        }
      }
      
      if (kDebugMode) {
        print('\nRevenue Summary:');
        print('- Customer Payments: $customerPayments MAD');
        print('- Admin Assignment Value: $adminAssignments MAD');
        print('- Total Revenue (Customer Only): $revenue MAD');
        print('- Combined Value: ${customerPayments + adminAssignments} MAD');
        print('- Selected Mode: ${revenueMode.value}');
        print('==========================');
      }
      
      // Update observable values based on revenue mode
      this.customerPayments.value = customerPayments;
      adminAssignmentValue.value = adminAssignments;
      
      // Set total revenue based on selected mode
      switch (revenueMode.value) {
        case 'customer_only':
          totalRevenue.value = customerPayments;
          if (kDebugMode) {
            print('Setting revenue to customer payments: $customerPayments');
          }
          break;
        case 'combined':
          totalRevenue.value = customerPayments + adminAssignments;
          if (kDebugMode) {
            print(
                'Setting revenue to combined: ${customerPayments + adminAssignments}');
          }
          break;
        case 'admin_value':
          totalRevenue.value = adminAssignments;
          if (kDebugMode) {
            print('Setting revenue to admin value: $adminAssignments');
          }
          break;
        default:
          totalRevenue.value = customerPayments;
          if (kDebugMode) {
            print(
                'Setting revenue to default (customer payments): $customerPayments');
          }
      }

      // Count active subscriptions
      int active = 0;
      if (kDebugMode) {
        print('=== SUBSCRIPTION DEBUG INFO ===');
        print('Total subscription documents: ${subscriptionsSnapshot.docs.length}');
      }
      
      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        final restaurantId = data['restaurantId'];
        final planName = data['planName'] ?? 'Unknown Plan';
        
        if (kDebugMode) {
          print('Subscription ${doc.id}: restaurantId=$restaurantId, status=$status, plan=$planName');
        }
        
        if (status == 'active') {
          active++;
        }
      }
      
      if (kDebugMode) {
        print('Active subscriptions count: $active');
        print('================================');
      }
      
      activeSubscriptions.value = active;

      // Count pending restaurant approvals
      final pendingApprovalSnapshot = await _firestore
          .collection('restaurant_registrations')
          .where('approvalStatus', isEqualTo: 'pending')
          .get();
      pendingApprovals.value = pendingApprovalSnapshot.docs.length;

      if (kDebugMode) {
        print('Dashboard metrics loaded successfully:');
        print('- Total Restaurants: ${totalRestaurants.value}');
        print('- Total Customers: ${totalCustomers.value}');
        print('- Active Subscriptions: ${activeSubscriptions.value}');
        print('- Total Revenue: ${totalRevenue.value} MAD');
        print('- Pending Approvals: ${pendingApprovals.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching dashboard metrics: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to load dashboard data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      // Reset metrics to 0 on error
      totalRestaurants.value = 0;
      totalCustomers.value = 0;
      activeSubscriptions.value = 0;
      totalRevenue.value = 0.0;
      customerPayments.value = 0.0;
      adminAssignmentValue.value = 0.0;
      pendingApprovals.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Load custom subscription plans
  Future<void> loadSubscriptionPlans() async {
    isLoadingSubscriptionPlans.value = true;
    try {
      final snapshot = await _firestore
          .collection('custom_subscription_plans')
          .orderBy('createdAt', descending: true)
          .get();

      final List<SubscriptionPlanModel> plans = [];
      for (var doc in snapshot.docs) {
        plans.add(SubscriptionPlanModel.fromFirestore(doc));
      }

      subscriptionPlans.value = plans;
      
      if (kDebugMode) {
        print('Loaded ${plans.length} subscription plans');
        print('Active plans: ${plans.where((p) => p.isActive).length}');
        print('Free trial plan: ${plans.where((p) => p.isFreeTrial).length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading subscription plans: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to load subscription plans',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingSubscriptionPlans.value = false;
    }
  }

  // Get the active free trial plan
  SubscriptionPlanModel? get freeTrialPlan {
    try {
      return subscriptionPlans.firstWhere((plan) => plan.isFreeTrial && plan.isActive);
    } catch (e) {
      return null;
    }
  }

  // Get all active plans including free trial
  List<SubscriptionPlanModel> get allActivePlans {
    return subscriptionPlans.where((plan) => plan.isActive).toList();
  }

  // Create a new subscription plan
  Future<void> createSubscriptionPlan({
    required String name,
    required String description,
    required int scanLimit,
    required int durationDays,
    required double price,
    String currency = 'MAD',
    required List<String> features,
    String planType = 'regular',
  }) async {
    try {
      final plan = SubscriptionPlanModel(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        scanLimit: scanLimit,
        durationDays: durationDays,
        price: price,
        currency: currency,
        isActive: true,
        createdAt: DateTime.now(),
        features: features,
        planType: planType,
      );

      await _firestore
          .collection('custom_subscription_plans')
          .add(plan.toFirestore());

      // Reload plans
      await loadSubscriptionPlans();

      Get.snackbar(
        'Success',
        'Subscription plan created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating subscription plan: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to create subscription plan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Update a subscription plan
  Future<void> updateSubscriptionPlan({
    required String planId,
    required String name,
    required String description,
    required int scanLimit,
    required int durationDays,
    required double price,
    String currency = 'MAD',
    required bool isActive,
    required List<String> features,
    String? planType,
  }) async {
    try {
      // Get existing plan to preserve planType if not provided
      final existingPlan = subscriptionPlans.firstWhere((p) => p.id == planId);
      
      final updatedPlan = SubscriptionPlanModel(
        id: planId,
        name: name,
        description: description,
        scanLimit: scanLimit,
        durationDays: durationDays,
        price: price,
        currency: currency,
        isActive: isActive,
        createdAt: existingPlan.createdAt, // Keep original creation date
        updatedAt: DateTime.now(),
        features: features,
        planType: planType ?? existingPlan.planType,
      );

      await _firestore
          .collection('custom_subscription_plans')
          .doc(planId)
          .update(updatedPlan.toFirestore());

      // Reload plans
      await loadSubscriptionPlans();

      Get.snackbar(
        'Success',
        'Subscription plan updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating subscription plan: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to update subscription plan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Delete a subscription plan
  Future<void> deleteSubscriptionPlan(String planId) async {
    try {
      await _firestore
          .collection('custom_subscription_plans')
          .doc(planId)
          .delete();

      // Reload plans
      await loadSubscriptionPlans();

      Get.snackbar(
        'Success',
        'Subscription plan deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting subscription plan: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to delete subscription plan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Create default free trial plan if it doesn't exist
  Future<void> createDefaultFreeTrialPlan() async {
    try {
      // Check if free trial plan already exists
      final existingFreeTrial = subscriptionPlans.where((plan) => plan.isFreeTrial).toList();
      
      if (existingFreeTrial.isNotEmpty) {
        if (kDebugMode) {
          print('Free trial plan already exists: ${existingFreeTrial.first.name}');
        }
        return;
      }

      // Create default free trial plan
      await createSubscriptionPlan(
        name: 'Free Trial',
        description: 'Free trial period for new restaurants',
        scanLimit: 100,
        durationDays: 30,
        price: 0.0,
        currency: 'MAD',
        features: [
          'Up to 100 customer scans',
          'Basic analytics',
          'Email support',
          'Perfect for testing the platform'
        ],
        planType: 'free_trial',
      );

      if (kDebugMode) {
        print('Default free trial plan created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating default free trial plan: $e');
      }
    }
  }

  // Toggle subscription plan active status
  Future<void> toggleSubscriptionPlanStatus(
      String planId, bool isActive) async {
    try {
      await _firestore
          .collection('custom_subscription_plans')
          .doc(planId)
          .update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });

      // Reload plans
      await loadSubscriptionPlans();

      Get.snackbar(
        'Success',
        'Subscription plan status updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling subscription plan status: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to update subscription plan status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Get active subscription plans (for admin assignment, including free trial)
  List<SubscriptionPlanModel> get activeSubscriptionPlans {
    return subscriptionPlans.where((plan) => plan.isActive).toList();
  }

  // Assign subscription plan to restaurant
  Future<void> assignSubscriptionPlan({
    required String restaurantId,
    required String planId,
    required int durationDays,
    bool resetScans = true,
  }) async {
    if (isAssigningSubscription.value) {
      // Prevent multiple simultaneous assignments
      return;
    }

    isAssigningSubscription.value = true;
    try {
      // Get the subscription plan details
      final plan = subscriptionPlans.firstWhere((p) => p.id == planId);

      // Calculate start and end dates
      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));

      // FIRST: Deactivate all existing active subscriptions for this restaurant
      final existingSubscriptions = await _firestore
          .collection('subscriptions')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'active')
          .get();

      if (kDebugMode) {
        print('Deactivating ${existingSubscriptions.docs.length} existing active subscriptions for restaurant: $restaurantId');
      }

      // Use batch to ensure atomic operation
      final batch = _firestore.batch();

      // Deactivate existing active subscriptions
      for (var doc in existingSubscriptions.docs) {
        batch.update(doc.reference, {
          'status': 'replaced',
          'replacedAt': Timestamp.now(),
          'replacedBy': _auth.currentUser?.uid,
        });
        
        if (kDebugMode) {
          print('Deactivating subscription: ${doc.id}');
        }
      }

      // Update restaurant subscription
      final restaurantRef = _firestore.collection('restaurants').doc(restaurantId);
      batch.update(restaurantRef, {
        'subscriptionPlan': planId,
        'subscriptionStatus': 'active',
        'subscriptionStart': Timestamp.fromDate(now),
        'subscriptionEnd': Timestamp.fromDate(endDate),
        'currentScanCount': 0, // Reset scan count for new subscription
        'updatedAt': Timestamp.now(),
      });

      // Create new subscription record
      final newSubscriptionRef = _firestore.collection('subscriptions').doc();
      batch.set(newSubscriptionRef, {
        'restaurantId': restaurantId,
        'planId': planId,
        'planName': plan.name,
        'planPrice': plan.price,
        'planCurrency': plan.currency,
        'durationDays': durationDays,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'active',
        'assignedBy': _auth.currentUser?.uid,
        'assignedAt': Timestamp.now(),
        'amountPaid': 0.0, // Admin assignment, no payment
        'paymentStatus': 'admin_assigned',
        'createdAt': Timestamp.now(),
      });

      // Commit the batch
      await batch.commit();

      // After successfully updating the subscription, delete old scan records if resetScans is true
      if (resetScans) {
        await _resetRestaurantScans(restaurantId, now);
      }

      Get.snackbar(
        'Success',
        'Subscription plan assigned successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh dashboard metrics to show updated count
      await fetchDashboardMetrics();
    } catch (e) {
      if (kDebugMode) {
        print('Error assigning subscription plan: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to assign subscription plan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isAssigningSubscription.value = false;
    }
  }

  // Helper method to reset restaurant scans when subscription changes
  Future<void> _resetRestaurantScans(
      String restaurantId, DateTime cutoffDate) async {
    try {
      // We don't actually delete the old scans for data integrity and reporting purposes
      // Instead, we'll mark them as "archived" by adding a field

      final oldScansSnapshot = await _firestore
          .collection('scans')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (oldScansSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('No old scans to archive for restaurant: $restaurantId');
        }
        return;
      }

      if (kDebugMode) {
        print(
            'Archiving ${oldScansSnapshot.docs.length} old scans for restaurant: $restaurantId');
      }

      // Use batches to update large numbers of documents
      // Firestore batches can handle up to 500 operations
      List<List<DocumentSnapshot>> batches = [];

      for (var i = 0; i < oldScansSnapshot.docs.length; i += 400) {
        final end = (i + 400 < oldScansSnapshot.docs.length)
            ? i + 400
            : oldScansSnapshot.docs.length;
        batches.add(oldScansSnapshot.docs.sublist(i, end));
      }

      for (var batchDocs in batches) {
        final writeBatch = _firestore.batch();

        for (var doc in batchDocs) {
          writeBatch.update(doc.reference, {
            'archivedAt': Timestamp.fromDate(cutoffDate),
            'archivedReason': 'subscription_change',
            'archivedBy': _auth.currentUser?.uid,
          });
        }

        await writeBatch.commit();
      }

      if (kDebugMode) {
        print('Successfully archived old scans for restaurant: $restaurantId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error archiving old scans: $e');
      }
    }
  }

  // Extend restaurant subscription
  Future<void> extendRestaurantSubscription({
    required String restaurantId,
    required int additionalDays,
  }) async {
    try {
      // Get current restaurant data
      final restaurantDoc =
          await _firestore.collection('restaurants').doc(restaurantId).get();

      if (!restaurantDoc.exists) {
        throw 'Restaurant not found';
      }

      final data = restaurantDoc.data()!;
      final currentEndDate = data['subscriptionEnd'] as Timestamp?;

      if (currentEndDate == null) {
        throw 'No active subscription found';
      }

      // Calculate new end date
      final newEndDate =
          currentEndDate.toDate().add(Duration(days: additionalDays));

      // Update restaurant subscription
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'subscriptionEnd': Timestamp.fromDate(newEndDate),
        'updatedAt': Timestamp.now(),
      });

      // Record extension
      await _firestore.collection('subscriptions').add({
        'restaurantId': restaurantId,
        'planId': data['subscriptionPlan'],
        'planName': data['subscriptionPlan'],
        'durationDays': additionalDays,
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(newEndDate),
        'status': 'extension',
        'assignedBy': _auth.currentUser?.uid,
        'assignedAt': Timestamp.now(),
        'amountPaid': 0.0,
        'paymentStatus': 'admin_extended',
        'note': 'Subscription extended by admin',
      });

      Get.snackbar(
        'Success',
        'Subscription extended successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error extending subscription: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to extend subscription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Bulk assign subscription plan to multiple restaurants
  Future<void> bulkAssignSubscriptionPlan({
    required List<String> restaurantIds,
    required String planId,
    required int durationDays,
    bool resetScans = true, // Add parameter to control scan reset
  }) async {
    try {
      // Get the subscription plan details
      final plan = subscriptionPlans.firstWhere((p) => p.id == planId);

      // Calculate start and end dates
      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));

      // Use batch write for better performance
      final batch = _firestore.batch();

      for (final restaurantId in restaurantIds) {
        // FIRST: Deactivate existing active subscriptions for this restaurant
        final existingSubscriptions = await _firestore
            .collection('subscriptions')
            .where('restaurantId', isEqualTo: restaurantId)
            .where('status', isEqualTo: 'active')
            .get();

        // Deactivate existing active subscriptions
        for (var doc in existingSubscriptions.docs) {
          batch.update(doc.reference, {
            'status': 'replaced',
            'replacedAt': Timestamp.now(),
            'replacedBy': _auth.currentUser?.uid,
          });
        }

        // Update restaurant subscription
        final restaurantRef =
            _firestore.collection('restaurants').doc(restaurantId);
        batch.update(restaurantRef, {
          'subscriptionPlan': planId,
          'subscriptionStatus': 'active',
          'subscriptionStart': Timestamp.fromDate(now),
          'subscriptionEnd': Timestamp.fromDate(endDate),
          'currentScanCount': 0, // Reset scan count for new subscription
          'updatedAt': Timestamp.now(),
        });

        // Record subscription assignment
        final subscriptionRef = _firestore.collection('subscriptions').doc();
        batch.set(subscriptionRef, {
          'restaurantId': restaurantId,
          'planId': planId,
          'planName': plan.name,
          'planPrice': plan.price,
          'planCurrency': plan.currency,
          'durationDays': durationDays,
          'startDate': Timestamp.fromDate(now),
          'endDate': Timestamp.fromDate(endDate),
          'status': 'active',
          'assignedBy': _auth.currentUser?.uid,
          'assignedAt': Timestamp.now(),
          'amountPaid': 0.0, // Admin assignment, no payment
          'paymentStatus': 'admin_assigned',
          'createdAt': Timestamp.now(),
        });
      }

      // Commit the batch
      await batch.commit();
      
      // After successfully updating subscriptions, reset scans for each restaurant if needed
      if (resetScans) {
        for (final restaurantId in restaurantIds) {
          await _resetRestaurantScans(restaurantId, now);
        }
      }

      Get.snackbar(
        'Success',
        'Subscription plan assigned to ${restaurantIds.length} restaurants successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh dashboard metrics to show updated count
      await fetchDashboardMetrics();
    } catch (e) {
      if (kDebugMode) {
        print('Error bulk assigning subscription plan: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to assign subscription plan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Load admin notifications
  Future<void> loadNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Listen to notifications collection with real-time updates
      _firestore
          .collection('admin_notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        final List<Map<String, dynamic>> notificationsList = [];
        int unread = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          notificationsList.add(data);

          if (data['read'] == false) {
            unread++;
          }
        }

        notifications.value = notificationsList;
        unreadNotifications.value = unread;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final batch = _firestore.batch();

      for (var notification in notifications) {
        if (notification['read'] == false) {
          final docRef = _firestore
              .collection('admin_notifications')
              .doc(notification['id']);
          batch.update(docRef, {'read': true});
        }
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to mark notifications as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Create a new admin notification (used by other parts of the app)
  Future<void> createAdminNotification({
    required String title,
    required String message,
    String? type,
    String? relatedId,
  }) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'title': title,
        'message': message,
        'type': type ?? 'info',
        'relatedId': relatedId,
        'read': false,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating admin notification: $e');
      }
    }
  }

  // Approve a restaurant
  Future<void> approveRestaurant(String registrationId) async {
    try {
      // 1. Get restaurant registration data
      DocumentSnapshot<Map<String, dynamic>> registrationSnapshot =
          await _firestore
              .collection('restaurant_registrations')
              .doc(registrationId)
              .get();

      // Fallback: if the provided id is actually the restaurant UID rather than registration doc id
      if (!registrationSnapshot.exists) {
        final query = await _firestore
            .collection('restaurant_registrations')
            .where('uid', isEqualTo: registrationId)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          registrationSnapshot = query.docs.first;
        }
      }

      if (!registrationSnapshot.exists) {
        throw 'Restaurant registration not found';
      }

      final registrationData = registrationSnapshot.data()!;
      final String restaurantUid = registrationData['uid'] ?? registrationId;
      final String restaurantName =
          registrationData['restaurantName'] ?? 'Unknown Restaurant';

      // 2. Update registration document
      await registrationSnapshot.reference.update({
        'approvalStatus': 'approved',
        'approvedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // 3. Update user document (if exists)
      await _firestore.collection('users').doc(restaurantUid).set({
        'approvalStatus': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. Get the initial plan
      final initialPlan = this.initialPlan;
      if (initialPlan == null) {
        Get.snackbar(
          'Approval Blocked',
          'No initial subscription plan is set. Please set an initial plan in the Custom Subscription Plans section before approving restaurants.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 5. Create / update restaurant document
      final now = DateTime.now();
      final planEndDate = now.add(Duration(days: initialPlan.durationDays));
      await _firestore.collection('restaurants').doc(restaurantUid).set({
        'uid': restaurantUid,
        'restaurantName': registrationData['restaurantName'] ?? '',
        'name':
            registrationData['restaurantName'] ?? '', // keep backward-compat
        'ownerName': registrationData['ownerName'] ?? '',
        'address': registrationData['postalAddress'] ?? '', // Use postal address as address
        'email': registrationData['email'] ?? '',
        'phoneNumber': registrationData['phoneNumber'] ?? '', // Already includes country code
        'postalAddress': registrationData['postalAddress'] ?? '',
        'logoUrl': registrationData['logoUrl'] ?? '',
        'supportEmail': registrationData['supportEmail'] ?? '',
        'bankDetails': registrationData['bankDetails'] ?? '',
        'ibanNumber': registrationData['ibanNumber'] ?? '',
        'subscriptionPlan': initialPlan.id,
        'subscriptionStatus': 'active', // Always set to 'active' for any valid subscription
        'currentScanCount': 0,
        'trialStartDate': Timestamp.fromDate(now),
        'subscriptionEnd': Timestamp.fromDate(planEndDate),
        'createdAt': FieldValue.serverTimestamp(),
        'approvalStatus': 'approved',
        'approvedAt': Timestamp.now(),
        'isSuspended': false,
        'isActive': true,
      }, SetOptions(merge: true));

      // 5. Ensure loyalty program exists
      await _firestore.collection('programs').doc(restaurantUid).set({
        'restaurantId': restaurantUid,
        'rewardType': 'Free Drink',
        'pointsRequired': 10,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 6. Notify admin team
      await createAdminNotification(
        title: 'Restaurant Approved',
        message: 'Restaurant "$restaurantName" has been approved',
        type: 'restaurant_approval',
        relatedId: restaurantUid,
      );

      // 7. Refresh metrics
      await fetchDashboardMetrics();

      // Debug: Confirm restaurant was moved to restaurants collection
      if (kDebugMode) {
        print('✅ Restaurant approved successfully:');
        print('   - Restaurant Name: $restaurantName');
        print('   - Restaurant UID: $restaurantUid');
        print('   - Added to restaurants collection with approvalStatus: approved');
        print('   - Should now appear in Restaurant Management page');
      }

      Get.snackbar(
        'Success',
        'Restaurant approved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error approving restaurant: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to approve restaurant: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Reject a restaurant
  Future<void> rejectRestaurant(String restaurantId, String reason) async {
    try {
      // Get restaurant registration data
      final registrationDoc = await _firestore
          .collection('restaurant_registrations')
          .doc(restaurantId)
          .get();

      if (!registrationDoc.exists) {
        throw 'Restaurant registration not found';
      }

      final registrationData = registrationDoc.data()!;
      final restaurantName =
          registrationData['restaurantName'] ?? 'Unknown Restaurant';

      // Update registration status
      await _firestore
          .collection('restaurant_registrations')
          .doc(restaurantId)
          .update({
        'approvalStatus': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Update user document
      await _firestore.collection('users').doc(restaurantId).update({
        'approvalStatus': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for admin
      await createAdminNotification(
        title: 'Restaurant Rejected',
        message: 'Restaurant "$restaurantName" has been rejected',
        type: 'restaurant_rejection',
        relatedId: restaurantId,
      );

      // Refresh dashboard metrics
      await fetchDashboardMetrics();

      Get.snackbar(
        'Success',
        'Restaurant rejected successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting restaurant: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to reject restaurant: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Export restaurant data to CSV
  Future<void> exportRestaurantsToCSV() async {
    try {
      isLoading.value = true;

      // Get all restaurants
      final restaurantsSnapshot =
          await _firestore.collection('restaurants').get();

      // Prepare CSV data
      List<List<dynamic>> csvData = [];

      // Add header row
      csvData.add([
        'ID',
        'Name',
        'Email',
        'Phone',
        'Address',
        'Subscription Plan',
        'Subscription Status',
        'Created At',
        'Approval Status'
      ]);

      // Add restaurant data rows
      for (var doc in restaurantsSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        String createdAtStr = createdAt != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate())
            : 'N/A';

        csvData.add([
          doc.id,
          data['name'] ?? 'N/A',
          data['email'] ?? 'N/A',
          data['phone'] ?? 'N/A',
          data['address'] ?? 'N/A',
          data['subscriptionPlan'] ?? 'No plan',
          data['subscriptionStatus'] ?? 'inactive',
          createdAtStr,
          data['approvalStatus'] ?? 'pending'
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(csvData);

      final bytes = Uint8List.fromList(utf8.encode(csv));

      await FileSaver.instance.saveFile(
        name: 'restaurants_export_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        ext: 'csv',
      );

      // Also drop copy for sharing
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/restaurants_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareFiles([path], text: 'Restaurants Export Data');

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting restaurants: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to export restaurant data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Export customer data to CSV
  Future<void> exportCustomersToCSV() async {
    try {
      isLoading.value = true;

      // Get all customers
      final customersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();

      // Prepare CSV data
      List<List<dynamic>> csvData = [];

      // Add header row
      csvData.add([
        'ID',
        'Name',
        'Email',
        'Phone',
        'Created At',
        'Last Login',
        'Total Scans'
      ]);

      // Add customer data rows
      for (var doc in customersSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        String createdAtStr = createdAt != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate())
            : 'N/A';

        final lastLogin = data['lastLogin'] as Timestamp?;
        String lastLoginStr = lastLogin != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(lastLogin.toDate())
            : 'Never';

        csvData.add([
          doc.id,
          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
          data['email'] ?? 'N/A',
          data['phone'] ?? 'N/A',
          createdAtStr,
          lastLoginStr,
          data['totalScans'] ?? 0
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(csvData);

      final bytes = Uint8List.fromList(utf8.encode(csv));

      await FileSaver.instance.saveFile(
        name: 'customers_export_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        ext: 'csv',
      );

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/customers_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareFiles([path], text: 'Customers Export Data');

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting customers: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to export customer data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Export subscriptions data to CSV
  Future<void> exportSubscriptionsToCSV() async {
    try {
      isLoading.value = true;

      // Get all subscriptions
      final subsSnapshot = await _firestore.collection('subscriptions').get();

      // Prepare CSV
      List<List<dynamic>> csvData = [];
      csvData.add([
        'ID',
        'Restaurant ID',
        'Plan',
        'Amount Paid',
        'Status',
        'Start Date',
        'End Date',
        'Created At'
      ]);

      for (var doc in subsSnapshot.docs) {
        final data = doc.data();
        String createdAtStr = '';
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          createdAtStr = DateFormat('yyyy-MM-dd HH:mm')
              .format((data['createdAt'] as Timestamp).toDate());
        }
        String startDateStr = '';
        if (data['startDate'] != null && data['startDate'] is Timestamp) {
          startDateStr = DateFormat('yyyy-MM-dd')
              .format((data['startDate'] as Timestamp).toDate());
        }
        String endDateStr = '';
        if (data['endDate'] != null && data['endDate'] is Timestamp) {
          endDateStr = DateFormat('yyyy-MM-dd')
              .format((data['endDate'] as Timestamp).toDate());
        }

        csvData.add([
          doc.id,
          data['restaurantId'] ?? 'N/A',
          data['plan'] ?? 'N/A',
          data['amountPaid'] ?? 0,
          data['status'] ?? 'N/A',
          startDateStr,
          endDateStr,
          createdAtStr,
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      final bytes = Uint8List.fromList(utf8.encode(csv));

      await FileSaver.instance.saveFile(
        name: 'subscriptions_export_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        ext: 'csv',
      );

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/subscriptions_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareFiles([path], text: 'Subscriptions Export Data');

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting subscriptions: $e');
      }
      Get.snackbar('Error', 'Failed to export subscriptions: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // Export scan activity to CSV
  Future<void> exportScansToCSV() async {
    try {
      isLoading.value = true;

      final scansSnapshot = await _firestore.collection('scans').get();

      List<List<dynamic>> csvData = [];
      csvData.add([
        'ID',
        'Restaurant ID',
        'Customer ID',
        'Points Awarded',
        'Timestamp'
      ]);

      for (var doc in scansSnapshot.docs) {
        final data = doc.data();
        String timestampStr = '';
        if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
          timestampStr = DateFormat('yyyy-MM-dd HH:mm')
              .format((data['timestamp'] as Timestamp).toDate());
        }

        csvData.add([
          doc.id,
          data['restaurantId'] ?? 'N/A',
          data['clientId'] ?? 'N/A',
          data['pointsAwarded'] ?? 0,
          timestampStr,
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      final bytes = Uint8List.fromList(utf8.encode(csv));

      await FileSaver.instance.saveFile(
        name: 'scans_export_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        ext: 'csv',
      );

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/scans_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareFiles([path], text: 'Scan Activity Export Data');

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting scans: $e');
      }
      Get.snackbar('Error', 'Failed to export scan activity: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
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
        'Failed to log out',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Filter restaurants by status
  void filterRestaurants(String filter) {
    selectedRestaurantFilter.value = filter;
  }

  // Search restaurants
  void searchRestaurants(String query) {
    restaurantSearchQuery.value = query;
  }

  // Filter customers
  void filterCustomers(String filter) {
    selectedCustomerFilter.value = filter;
  }

  // Search customers
  void searchCustomers(String query) {
    customerSearchQuery.value = query;
  }

  // Get filtered and searched restaurants stream
  Stream<QuerySnapshot> getFilteredRestaurantsStream() {
    Query query = _firestore.collection('restaurants');

    // Apply status filter if not 'all'
    if (selectedRestaurantFilter.value != 'all') {
      if (selectedRestaurantFilter.value == 'active') {
        query = query.where('subscriptionStatus', isEqualTo: 'active');
      } else if (selectedRestaurantFilter.value == 'inactive') {
        query = query.where('subscriptionStatus', isEqualTo: 'inactive');
      } else if (selectedRestaurantFilter.value == 'pending') {
        query = query.where('approvalStatus', isEqualTo: 'pending');
      } else if (selectedRestaurantFilter.value == 'suspended') {
        query = query.where('isSuspended', isEqualTo: true);
      }
    }

    // Debug: Log what filter is being applied
    if (kDebugMode) {
      print('Restaurant filter applied: ${selectedRestaurantFilter.value}');
      print('Querying restaurants collection with filter: ${selectedRestaurantFilter.value}');
    }

    // We can't perform text search directly in Firestore query
    // The search will be applied in the UI after data is fetched

    return query.snapshots();
  }

  // Get filtered and searched customers stream
  Stream<QuerySnapshot> getFilteredCustomersStream() {
    Query query =
        _firestore.collection('users').where('role', isEqualTo: 'customer');

    // Apply status filter if not 'all'
    if (selectedCustomerFilter.value != 'all') {
      if (selectedCustomerFilter.value == 'active') {
        // Consider users active if they logged in within the last 30 days
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        query = query.where('lastLogin',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo));
      } else if (selectedCustomerFilter.value == 'new') {
        // New users registered in the last 7 days
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo));
      }
    }

    return query.snapshots();
  }



  // Fetch loyalty program data
  Future<void> fetchLoyaltyProgramData() async {
    isLoadingLoyaltyData.value = true;
    try {
      await Future.wait([
        fetchLoyaltyPrograms(),
        fetchRecentClaims(),
        fetchLoyaltyStats(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching loyalty program data: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to load loyalty program data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingLoyaltyData.value = false;
    }
  }

  // Fetch all restaurant loyalty programs
  Future<void> fetchLoyaltyPrograms() async {
    try {
      final programsSnapshot = await _firestore.collection('programs').get();

      final List<Map<String, dynamic>> programs = [];

      for (var doc in programsSnapshot.docs) {
        final restaurantId = doc.id;
        final programData = doc.data();

        // Get restaurant name
        final restaurantDoc =
            await _firestore.collection('restaurants').doc(restaurantId).get();
        final restaurantName = restaurantDoc.exists
            ? (restaurantDoc.data()?['name'] as String?) ?? 'Unknown'
            : 'Unknown';

        programs.add({
          'id': doc.id,
          'restaurantId': restaurantId,
          'restaurantName': restaurantName,
          'rewardType': programData['rewardType'] ?? 'Unknown',
          'pointsRequired': programData['pointsRequired'] ?? 10,
          'createdAt': programData['createdAt'] ?? Timestamp.now(),
        });
      }

      loyaltyPrograms.assignAll(programs);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching loyalty programs: $e');
      }
      rethrow;
    }
  }

  // Fetch recent reward claims
  Future<void> fetchRecentClaims() async {
    try {
      final claimsSnapshot = await _firestore
          .collection('claims')
          .orderBy('claimDate', descending: true)
          .limit(20)
          .get();

      final List<Map<String, dynamic>> claims = [];

      for (var doc in claimsSnapshot.docs) {
        final data = doc.data();

        claims.add({
          'id': doc.id,
          'customerId': data['customerId'] ?? '',
          'restaurantId': data['restaurantId'] ?? '',
          'restaurantName': data['restaurantName'] ?? 'Unknown Restaurant',
          'rewardType': data['rewardType'] ?? 'Unknown Reward',
          'claimDate': data['claimDate'] ?? Timestamp.now(),
          'pointsUsed': data['pointsUsed'] ?? 0,
        });
      }

      recentClaims.assignAll(claims);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching recent claims: $e');
      }
      rethrow;
    }
  }

  // Fetch loyalty program statistics
  Future<void> fetchLoyaltyStats() async {
    try {
      // Get total number of claimed rewards
      final claimsSnapshot =
          await _firestore.collection('claims').count().get();
      totalRewardsClaimed.value = claimsSnapshot.count!;

      // Get top restaurants by reward claims
      final restaurantsSnapshot =
          await _firestore.collection('restaurants').get();
      Map<String, int> restaurantClaims = {};

      for (var doc in restaurantsSnapshot.docs) {
        final restaurantName = doc.data()['name'] ?? 'Unknown';
        final totalClaimed = doc.data()['totalRewardsClaimed'] ?? 0;

        if (totalClaimed > 0) {
          restaurantClaims[restaurantName] = totalClaimed;
        }
      }

      // Sort by number of claims (descending) and take top 5
      final sortedRestaurants = restaurantClaims.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      Map<String, int> topRestaurants = {};
      for (var entry in sortedRestaurants.take(5)) {
        topRestaurants[entry.key] = entry.value;
      }

      topRestaurantsByRewards.value = topRestaurants;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching loyalty stats: $e');
      }
      rethrow;
    }
  }

  // ===== PDF EXPORT HELPERS =====
  Future<String> _exportTableToPDF({
    required List<List<dynamic>> tableData,
    required String baseFilename,
    required String shareText,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Table.fromTextArray(
            headers: tableData.first.map((e) => e.toString()).toList(),
            data: tableData
                .skip(1)
                .map((row) => row.map((e) => e.toString()).toList())
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: pw.TableBorder.all(),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0E0E0)),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    // Let user pick location
    await FileSaver.instance.saveFile(
      name: '${baseFilename}_${DateTime.now().millisecondsSinceEpoch}',
      bytes: bytes,
      ext: 'pdf',
    );

    // Also place a copy in app documents for sharing
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/${baseFilename}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes);

    await Share.shareFiles([path], text: shareText);
    return path;
  }

  // Export functions to PDF
  Future<void> exportRestaurantsToPDF() async {
    try {
      isLoading.value = true;

      final restaurantsSnapshot =
          await _firestore.collection('restaurants').get();

      List<List<dynamic>> pdfData = [];
      pdfData.add([
        'ID',
        'Name',
        'Email',
        'Phone',
        'Address',
        'Subscription Plan',
        'Subscription Status',
        'Created At',
        'Approval Status'
      ]);

      for (var doc in restaurantsSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        String createdAtStr = createdAt != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate())
            : 'N/A';

        pdfData.add([
          doc.id,
          data['name'] ?? 'N/A',
          data['email'] ?? 'N/A',
          data['phone'] ?? 'N/A',
          data['address'] ?? 'N/A',
          data['subscriptionPlan'] ?? 'No plan',
          data['subscriptionStatus'] ?? 'inactive',
          createdAtStr,
          data['approvalStatus'] ?? 'pending'
        ]);
      }

      await _exportTableToPDF(
        tableData: pdfData,
        baseFilename: 'restaurants_export',
        shareText: 'Restaurants Export Data (PDF)',
      );

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting restaurants PDF: $e');
      }
      Get.snackbar('Error', 'Failed to export restaurant PDF: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> exportCustomersToPDF() async {
    try {
      isLoading.value = true;

      final customersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();

      List<List<dynamic>> pdfData = [];
      pdfData.add([
        'ID',
        'Name',
        'Email',
        'Phone',
        'Created At',
        'Last Login',
        'Total Scans'
      ]);

      for (var doc in customersSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        String createdAtStr = createdAt != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate())
            : 'N/A';

        final lastLogin = data['lastLogin'] as Timestamp?;
        String lastLoginStr = lastLogin != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(lastLogin.toDate())
            : 'Never';

        pdfData.add([
          doc.id,
          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
          data['email'] ?? 'N/A',
          data['phone'] ?? 'N/A',
          createdAtStr,
          lastLoginStr,
          data['totalScans'] ?? 0,
        ]);
      }

      await _exportTableToPDF(
        tableData: pdfData,
        baseFilename: 'customers_export',
        shareText: 'Customers Export Data (PDF)',
      );

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting customers PDF: $e');
      }
      Get.snackbar('Error', 'Failed to export customers PDF: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> exportSubscriptionsToPDF() async {
    try {
      isLoading.value = true;
      final subsSnapshot = await _firestore.collection('subscriptions').get();

      List<List<dynamic>> pdfData = [];
      pdfData.add([
        'ID',
        'Restaurant ID',
        'Plan',
        'Amount Paid',
        'Status',
        'Start Date',
        'End Date',
        'Created At'
      ]);

      for (var doc in subsSnapshot.docs) {
        final data = doc.data();
        String createdAtStr = '';
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          createdAtStr = DateFormat('yyyy-MM-dd HH:mm')
              .format((data['createdAt'] as Timestamp).toDate());
        }
        String startDateStr = '';
        if (data['startDate'] != null && data['startDate'] is Timestamp) {
          startDateStr = DateFormat('yyyy-MM-dd')
              .format((data['startDate'] as Timestamp).toDate());
        }
        String endDateStr = '';
        if (data['endDate'] != null && data['endDate'] is Timestamp) {
          endDateStr = DateFormat('yyyy-MM-dd')
              .format((data['endDate'] as Timestamp).toDate());
        }

        pdfData.add([
          doc.id,
          data['restaurantId'] ?? 'N/A',
          data['plan'] ?? 'N/A',
          data['amountPaid'] ?? 0,
          data['status'] ?? 'N/A',
          startDateStr,
          endDateStr,
          createdAtStr,
        ]);
      }

      await _exportTableToPDF(
        tableData: pdfData,
        baseFilename: 'subscriptions_export',
        shareText: 'Subscriptions Export Data (PDF)',
      );

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting subscriptions PDF: $e');
      }
      Get.snackbar('Error', 'Failed to export subscriptions PDF: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> exportScansToPDF() async {
    try {
      isLoading.value = true;
      final scansSnapshot = await _firestore.collection('scans').get();

      List<List<dynamic>> pdfData = [];
      pdfData.add([
        'ID',
        'Restaurant ID',
        'Customer ID',
        'Points Awarded',
        'Timestamp'
      ]);

      for (var doc in scansSnapshot.docs) {
        final data = doc.data();
        String timestampStr = '';
        if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
          timestampStr = DateFormat('yyyy-MM-dd HH:mm')
              .format((data['timestamp'] as Timestamp).toDate());
        }

        pdfData.add([
          doc.id,
          data['restaurantId'] ?? 'N/A',
          data['clientId'] ?? 'N/A',
          data['pointsAwarded'] ?? 0,
          timestampStr,
        ]);
      }

      await _exportTableToPDF(
        tableData: pdfData,
        baseFilename: 'scans_export',
        shareText: 'Scan Activity Export Data (PDF)',
      );

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting scans PDF: $e');
      }
      Get.snackbar('Error', 'Failed to export scan PDFs: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // ===== Reward Claims Export =====
  Future<void> exportRewardClaimsToCSV() async {
    try {
      isLoading.value = true;

      final claimsSnapshot = await _firestore.collection('claims').get();

      List<List<dynamic>> csvData = [];
      csvData.add([
        'ID',
        'Restaurant Name',
        'Customer ID',
        'Reward Type',
        'Points Used',
        'Claim Date'
      ]);

      for (var doc in claimsSnapshot.docs) {
        final data = doc.data();
        final claimDate = data['claimDate'] as Timestamp?;
        String claimDateStr = claimDate != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(claimDate.toDate())
            : 'N/A';

        csvData.add([
          doc.id,
          data['restaurantName'] ?? 'Unknown',
          data['customerId'] ?? 'Unknown',
          data['rewardType'] ?? 'Unknown',
          data['pointsUsed'] ?? 0,
          claimDateStr,
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      final bytes = Uint8List.fromList(utf8.encode(csv));

      await FileSaver.instance.saveFile(
        name: 'reward_claims_export_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        ext: 'csv',
      );

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/reward_claims_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareFiles([path], text: 'Reward Claims Export Data');

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting reward claims CSV: $e');
      }
      Get.snackbar('Error', 'Failed to export reward claims: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> exportRewardClaimsToPDF() async {
    try {
      isLoading.value = true;

      final claimsSnapshot = await _firestore.collection('claims').get();

      List<List<dynamic>> pdfData = [];
      pdfData.add([
        'ID',
        'Restaurant Name',
        'Customer ID',
        'Reward Type',
        'Points Used',
        'Claim Date'
      ]);

      for (var doc in claimsSnapshot.docs) {
        final data = doc.data();
        final claimDate = data['claimDate'] as Timestamp?;
        String claimDateStr = claimDate != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(claimDate.toDate())
            : 'N/A';

        pdfData.add([
          doc.id,
          data['restaurantName'] ?? 'Unknown',
          data['customerId'] ?? 'Unknown',
          data['rewardType'] ?? 'Unknown',
          data['pointsUsed'] ?? 0,
          claimDateStr,
        ]);
      }

      await _exportTableToPDF(
          tableData: pdfData,
          baseFilename: 'reward_claims_export',
          shareText: 'Reward Claims Export Data (PDF)');

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) {
        print('Error exporting reward claims PDF: $e');
      }
      Get.snackbar('Error', 'Failed to export reward claims PDF: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // Clean up duplicate active subscriptions
  Future<void> cleanupDuplicateSubscriptions() async {
    try {
      Get.dialog(
        const AlertDialog(
          title: Text('Cleaning Up Subscriptions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Please wait while we fix duplicate subscriptions...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final subscriptionsSnapshot = await _firestore.collection('subscriptions').get();
      
      // Group subscriptions by restaurant
      Map<String, List<QueryDocumentSnapshot>> subscriptionsByRestaurant = {};
      
      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final restaurantId = data?['restaurantId'] as String?;
        if (restaurantId != null) {
          if (!subscriptionsByRestaurant.containsKey(restaurantId)) {
            subscriptionsByRestaurant[restaurantId] = [];
          }
          subscriptionsByRestaurant[restaurantId]!.add(doc);
        }
      }
      
      int totalCleaned = 0;
      
      // For each restaurant, keep only the most recent active subscription
      for (var entry in subscriptionsByRestaurant.entries) {
        final restaurantId = entry.key;
        final subscriptions = entry.value;
        
        // Filter active subscriptions
        final activeSubscriptions = subscriptions.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['status'] == 'active';
        }).toList();
        
        if (activeSubscriptions.length > 1) {
          // Sort by creation date (most recent first)
          activeSubscriptions.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aDate = (aData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bDate = (bData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bDate.compareTo(aDate);
          });
          
          // Keep the first (most recent), deactivate the rest
          for (int i = 1; i < activeSubscriptions.length; i++) {
            await _firestore.collection('subscriptions')
                .doc(activeSubscriptions[i].id)
                .update({'status': 'expired'});
            totalCleaned++;
            
            if (kDebugMode) {
              print('Deactivated duplicate subscription: ${activeSubscriptions[i].id} for restaurant: $restaurantId');
            }
          }
        }
      }
      
      Get.back(); // Close loading dialog
      
      Get.snackbar(
        'Cleanup Complete',
        'Deactivated $totalCleaned duplicate subscriptions. Each restaurant now has only 1 active subscription.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      
      // Refresh dashboard metrics
      await fetchDashboardMetrics();
      
    } catch (e) {
      Get.back(); // Close loading dialog
      
      if (kDebugMode) {
        print('Error cleaning up subscriptions: $e');
      }
      
      Get.snackbar(
        'Cleanup Failed',
        'Failed to clean up subscriptions: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Switch revenue calculation mode
  void switchRevenueMode(String mode) {
    revenueMode.value = mode;
    
    // Recalculate total revenue based on new mode
    switch (mode) {
      case 'customer_only':
        totalRevenue.value = customerPayments.value;
        break;
      case 'combined':
        totalRevenue.value = customerPayments.value + adminAssignmentValue.value;
        break;
      case 'admin_value':
        totalRevenue.value = adminAssignmentValue.value;
        break;
      default:
        totalRevenue.value = customerPayments.value;
    }
    
    if (kDebugMode) {
      print('Revenue mode switched to: $mode');
      print('Total Revenue now shows: ${totalRevenue.value} MAD');
    }
    
    Get.snackbar(
      'Revenue Mode Updated',
      _getRevenueModeDescription(mode),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
  
  String _getRevenueModeDescription(String mode) {
    switch (mode) {
      case 'customer_only':
        return 'Showing only actual customer payments';
      case 'combined':
        return 'Showing customer payments + admin assignment value';
      case 'admin_value':
        return 'Showing admin assignment value only';
      default:
        return 'Showing customer payments only';
    }
  }

  // Clean up all Firebase data except admin credentials
  Future<void> cleanupAllFirebaseData() async {
    try {
      // Collections to be deleted (everything except admin-related)
      final collectionsToDelete = [
        'restaurants',
        'restaurant_registrations', 
        'users', // Will preserve admin users separately
        'subscriptions',
        'custom_subscription_plans',
        'subscription_plans', // Legacy subscription plans
        'programs',
        'scans',
        'claims',
        'customer_loyalty',
        'qr_codes',
        'offers', // Offers/promotions
        'system_activities', // System activity logs
        'admin_notifications', // Optional: you might want to keep these
      ];

      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 30),
              SizedBox(width: 12),
              Text('⚠️ DANGER ZONE'),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(Get.context!).size.height * 0.6,
              maxWidth: MediaQuery.of(Get.context!).size.width * 0.9,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will DELETE ALL Firebase data except:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 12),
                  Text('✅ PRESERVED:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('• Admin collection'),
                  Text('• Your admin user account'),
                  Text('• Admin authentication'),
                  SizedBox(height: 12),
                  Text('❌ DELETED:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ...collectionsToDelete.map((collection) => Text('• $collection')),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⚠️ THIS CANNOT BE UNDONE!\nAll restaurants, customers, and subscription data will be permanently lost.',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _showFinalConfirmation(collectionsToDelete);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Continue to Final Confirmation'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to initiate cleanup: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showFinalConfirmation(List<String> collectionsToDelete) {
    final RxString confirmText = ''.obs;
    
    Get.dialog(
      AlertDialog(
        title: Text('🔥 FINAL CONFIRMATION'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.3,
            maxWidth: MediaQuery.of(Get.context!).size.width * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Type "DELETE ALL DATA" to confirm:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Confirmation Text',
                    border: OutlineInputBorder(),
                    hintText: 'DELETE ALL DATA',
                  ),
                  style: TextStyle(fontWeight: FontWeight.bold),
                  onChanged: (value) => confirmText.value = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
            onPressed: confirmText.value == 'DELETE ALL DATA' 
                ? () {
                    Get.back();
                    _executeCleanup(collectionsToDelete);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('DELETE ALL DATA'),
          )),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _executeCleanup(List<String> collectionsToDelete) async {
    try {
      // Show progress dialog
      Get.dialog(
        AlertDialog(
          title: Text('🧹 Cleaning Database'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(Get.context!).size.width * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting all data except admin credentials...'),
                SizedBox(height: 8),
                Text('This may take a few moments.'),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      int totalDeleted = 0;
      final currentAdminUid = _auth.currentUser?.uid;

      if (kDebugMode) {
        print('🧹 Starting Firebase cleanup...');
        print('Preserving admin UID: $currentAdminUid');
      }

      // Delete each collection
      for (String collectionName in collectionsToDelete) {
        if (kDebugMode) {
          print('Deleting collection: $collectionName');
        }

        final collection = _firestore.collection(collectionName);
        
        if (collectionName == 'users') {
          // Special handling for users - preserve admin users
          final usersSnapshot = await collection.get();
          
          for (var doc in usersSnapshot.docs) {
            final data = doc.data();
            final userRole = data['role'] as String?;
            
            // Delete non-admin users only
            if (userRole != 'admin' && userRole != 'super_admin') {
              await doc.reference.delete();
              totalDeleted++;
              if (kDebugMode) {
                print('Deleted user: ${doc.id} (role: $userRole)');
              }
            } else {
              if (kDebugMode) {
                print('Preserved admin user: ${doc.id} (role: $userRole)');
              }
            }
          }
        } else {
          // Delete entire collection
          final snapshot = await collection.get();
          
          for (var doc in snapshot.docs) {
            await doc.reference.delete();
            totalDeleted++;
          }
          
          if (kDebugMode) {
            print('Deleted ${snapshot.docs.length} documents from $collectionName');
          }
        }
      }

      // Reset all dashboard metrics
      totalRestaurants.value = 0;
      totalCustomers.value = 0;
      activeSubscriptions.value = 0;
      totalRevenue.value = 0.0;
      customerPayments.value = 0.0;
      adminAssignmentValue.value = 0.0;
      pendingApprovals.value = 0;
      newRestaurantsThisMonth.value = 0;

      // Clear observable lists
      subscriptionPlans.clear();
      loyaltyPrograms.clear();
      recentClaims.clear();
      notifications.clear();
      totalRewardsClaimed.value = 0;
      unreadNotifications.value = 0;

      Get.back(); // Close progress dialog

      Get.snackbar(
        '✅ Cleanup Complete',
        'Successfully deleted $totalDeleted records.\nOnly admin data has been preserved.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      if (kDebugMode) {
        print('🎉 Firebase cleanup completed successfully!');
        print('Total records deleted: $totalDeleted');
        print('Admin data preserved ✅');
      }

    } catch (e) {
      Get.back(); // Close progress dialog
      
      if (kDebugMode) {
        print('❌ Error during Firebase cleanup: $e');
      }
      
      Get.snackbar(
        '❌ Cleanup Failed',
        'An error occurred during cleanup: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // Customer Management Methods
  Future<void> updateCustomerDetails({
    required String customerId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
  }) async {
    try {
      isLoading.value = true;

      // Update the customer document
      await _firestore.collection('users').doc(customerId).update({
        'firstName': firstName,
        'lastName': lastName,
        'name': '$firstName $lastName',
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Customer details updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating customer details: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to update customer details: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createCustomerAccount({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = userCredential.user!;

      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'registrationComplete': false, // Customer needs to complete registration
      });

      // Send email verification
      await user.sendEmailVerification();

      Get.snackbar(
        'Success',
        'Customer account created successfully. Verification email sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      if (kDebugMode) {
        print('Customer account created: ${user.uid}');
        print('Email verification sent to: $email');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to create customer account';
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account with this email already exists';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Please use a stronger password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      if (kDebugMode) {
        print('FirebaseAuthException in createCustomerAccount: ${e.code} - ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating customer account: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to create customer account: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getCustomerDetails(String customerId) async {
    try {
      final doc = await _firestore.collection('users').doc(customerId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting customer details: $e');
      }
      return null;
    }
  }

  // Customer Restriction Methods
  Future<void> restrictCustomer(String customerId, {String? reason}) async {
    try {
      isLoading.value = true;

      await _firestore.collection('users').doc(customerId).update({
        'isRestricted': true,
        'restrictionReason': reason ?? 'Admin restriction',
        'restrictedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Customer has been restricted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error restricting customer: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to restrict customer: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> unrestrictCustomer(String customerId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('users').doc(customerId).update({
        'isRestricted': false,
        'restrictionReason': null,
        'restrictedAt': null,
        'unrestrictedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Customer restriction has been removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error unrestricting customer: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to remove customer restriction: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Point Earning Limit Methods
  Future<void> setCustomerPointLimit(String customerId, int dailyLimit) async {
    try {
      isLoading.value = true;

      await _firestore.collection('users').doc(customerId).update({
        'dailyPointLimit': dailyLimit,
        'pointLimitSetAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Daily point limit set to $dailyLimit points',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error setting point limit: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to set point limit: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeCustomerPointLimit(String customerId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('users').doc(customerId).update({
        'dailyPointLimit': null,
        'pointLimitSetAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Daily point limit has been removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error removing point limit: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to remove point limit: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get customer's daily point usage
  Future<Map<String, dynamic>> getCustomerDailyPointUsage(String customerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final scansSnapshot = await _firestore
          .collection('scans')
          .where('clientId', isEqualTo: customerId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      int totalPointsToday = 0;
      Map<String, int> pointsByRestaurant = {};

      for (var doc in scansSnapshot.docs) {
        final data = doc.data();
        final points = data['pointsAwarded'] as int? ?? 0;
        final restaurantId = data['restaurantId'] as String? ?? '';
        
        totalPointsToday += points;
        if (restaurantId.isNotEmpty) {
          pointsByRestaurant[restaurantId] = (pointsByRestaurant[restaurantId] ?? 0) + points;
        }
      }

      return {
        'totalPointsToday': totalPointsToday,
        'pointsByRestaurant': pointsByRestaurant,
        'scanCountToday': scansSnapshot.docs.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting daily point usage: $e');
      }
      return {
        'totalPointsToday': 0,
        'pointsByRestaurant': {},
        'scanCountToday': 0,
      };
    }
  }

  // Get the initial plan (isInitial == true)
  SubscriptionPlanModel? get initialPlan {
    try {
      return subscriptionPlans.firstWhere((plan) => plan.isInitial && plan.isActive);
    } catch (e) {
      return null;
    }
  }

  // Set a plan as the initial plan
  Future<void> setInitialSubscriptionPlan(String planId) async {
    try {
      // Unset isInitial for all plans
      final batch = _firestore.batch();
      for (final plan in subscriptionPlans) {
        final docRef = _firestore.collection('custom_subscription_plans').doc(plan.id);
        batch.update(docRef, {'isInitial': plan.id == planId});
      }
      await batch.commit();
      await loadSubscriptionPlans();
      Get.snackbar('Success', 'Initial plan updated', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to set initial plan: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }


}
