import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../routes/app_pages.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

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
  final RxInt activeSubscriptions = 0.obs;
  final RxInt pendingApprovals = 0.obs;

  // Subscription plan pricing
  final RxMap<String, double> planPrices = <String, double>{}.obs;
  final RxBool isPricingLoading = false.obs;

  // Observable variables for loyalty program data
  final RxList<Map<String, dynamic>> loyaltyPrograms =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> recentClaims =
      <Map<String, dynamic>>[].obs;
  final RxInt totalRewardsClaimed = 0.obs;
  final RxBool isLoadingLoyaltyData = false.obs;
  final RxMap<String, int> topRestaurantsByRewards = <String, int>{}.obs;

  // Analytics data
  final RxList<Map<String, dynamic>> restaurantGrowthData =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> loyaltyUsageData =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> revenueBreakdownData =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> claimActivityByDayData =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingAnalytics = false.obs;

  // Admin notifications
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxInt unreadNotifications = 0.obs;

  // Search and filter
  final RxString restaurantSearchQuery = ''.obs;
  final RxString customerSearchQuery = ''.obs;
  final RxString selectedRestaurantFilter = 'all'.obs;
  final RxString selectedCustomerFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    // Check if user is already logged in as admin
    checkAdminAuth();
    // Load subscription plan prices
    loadPlanPrices();
    // Load admin notifications
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

      // Count active subscriptions
      int active = 0;
      for (var doc in subscriptionsSnapshot.docs) {
        if (doc.data()['status'] == 'active') {
          active++;
        }
      }
      activeSubscriptions.value = active;

      // Count pending restaurant approvals
      final pendingApprovalSnapshot = await _firestore
          .collection('restaurants')
          .where('approvalStatus', isEqualTo: 'pending')
          .get();
      pendingApprovals.value = pendingApprovalSnapshot.docs.length;
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

  // Load subscription plan prices from Firestore
  Future<void> loadPlanPrices() async {
    isPricingLoading.value = true;
    try {
      // Get default plans document from subscription_plans collection
      final plansDoc = await _firestore
          .collection('subscription_plans')
          .doc('default')
          .get();

      if (plansDoc.exists) {
        // If document exists, load prices
        final data = plansDoc.data() as Map<String, dynamic>;

        // Initialize with defaults if not present
        planPrices.value = {
          'plan_100': (data['plan_100'] as num?)?.toDouble() ?? 99.99,
          'plan_250': (data['plan_250'] as num?)?.toDouble() ?? 199.99,
          'plan_unlimited':
              (data['plan_unlimited'] as num?)?.toDouble() ?? 299.99,
        };
      } else {
        // If no document exists, create one with default prices
        await _firestore.collection('subscription_plans').doc('default').set({
          'plan_100': 99.99,
          'plan_250': 199.99,
          'plan_unlimited': 299.99,
          'updatedAt': Timestamp.now(),
        });

        // Set default prices in observable
        planPrices.value = {
          'plan_100': 99.99,
          'plan_250': 199.99,
          'plan_unlimited': 299.99,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading plan prices: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to load subscription plan prices',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPricingLoading.value = false;
    }
  }

  // Update subscription plan prices
  Future<void> updatePlanPrices(Map<String, double> newPrices) async {
    isPricingLoading.value = true;
    try {
      await _firestore.collection('subscription_plans').doc('default').update({
        'plan_100': newPrices['plan_100'],
        'plan_250': newPrices['plan_250'],
        'plan_unlimited': newPrices['plan_unlimited'],
        'updatedAt': Timestamp.now(),
      });

      // Update local observable
      planPrices.value = newPrices;

      Get.snackbar(
        'Success',
        'Subscription plan prices updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating plan prices: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to update subscription plan prices',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPricingLoading.value = false;
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
  Future<void> approveRestaurant(String restaurantId) async {
    try {
      // Get restaurant data
      final restaurantDoc =
          await _firestore.collection('restaurants').doc(restaurantId).get();
      final restaurantData = restaurantDoc.data();

      if (restaurantData == null) {
        throw 'Restaurant not found';
      }

      // Update restaurant status
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'approvalStatus': 'approved',
        'approvedAt': Timestamp.now(),
      });

      // Create notification for admin
      await createAdminNotification(
        title: 'Restaurant Approved',
        message: 'Restaurant "${restaurantData['name']}" has been approved',
        type: 'restaurant_approval',
        relatedId: restaurantId,
      );

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
      // Get restaurant data
      final restaurantDoc =
          await _firestore.collection('restaurants').doc(restaurantId).get();
      final restaurantData = restaurantDoc.data();

      if (restaurantData == null) {
        throw 'Restaurant not found';
      }

      // Update restaurant status
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'approvalStatus': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': Timestamp.now(),
      });

      // Create notification for admin
      await createAdminNotification(
        title: 'Restaurant Rejected',
        message: 'Restaurant "${restaurantData['name']}" has been rejected',
        type: 'restaurant_rejection',
        relatedId: restaurantId,
      );

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

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/restaurants_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      // Share file
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

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/customers_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      // Share file
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

  // Enhanced analytics: fetch detailed revenue data
  Future<void> fetchDetailedRevenueData() async {
    try {
      isLoadingAnalytics.value = true;

      // Get subscription data for the last 12 months
      final DateTime twelveMonthsAgo =
          DateTime.now().subtract(const Duration(days: 365));
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(twelveMonthsAgo))
          .get();

      // Group by month
      Map<String, double> monthlyRevenue = {};
      Map<String, Map<String, double>> planRevenue = {};

      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        final amount = (data['amountPaid'] as num?)?.toDouble() ?? 0.0;
        final plan = data['planType'] as String? ?? 'unknown';

        if (createdAt != null) {
          final date = createdAt.toDate();
          final monthYear = DateFormat('yyyy-MM').format(date);

          // Add to monthly revenue
          if (monthlyRevenue.containsKey(monthYear)) {
            monthlyRevenue[monthYear] =
                (monthlyRevenue[monthYear] ?? 0) + amount;
          } else {
            monthlyRevenue[monthYear] = amount;
          }

          // Add to plan revenue
          if (!planRevenue.containsKey(monthYear)) {
            planRevenue[monthYear] = {};
          }

          if (planRevenue[monthYear]!.containsKey(plan)) {
            planRevenue[monthYear]![plan] =
                (planRevenue[monthYear]![plan] ?? 0) + amount;
          } else {
            planRevenue[monthYear]![plan] = amount;
          }
        }
      }

      // Convert to list for charts
      List<Map<String, dynamic>> revenueData = [];
      List<Map<String, dynamic>> planData = [];

      monthlyRevenue.forEach((month, revenue) {
        revenueData.add({
          'month': month,
          'revenue': revenue,
        });

        // Add plan breakdown
        if (planRevenue.containsKey(month)) {
          planRevenue[month]!.forEach((plan, amount) {
            planData.add({
              'month': month,
              'plan': plan,
              'revenue': amount,
            });
          });
        }
      });

      // Sort by month
      revenueData.sort((a, b) => a['month'].compareTo(b['month']));

      // Update observable
      revenueBreakdownData.value = revenueData;

      isLoadingAnalytics.value = false;
    } catch (e) {
      isLoadingAnalytics.value = false;
      if (kDebugMode) {
        print('Error fetching detailed revenue data: $e');
      }
    }
  }

  // Fetch analytics data
  Future<void> fetchAnalyticsData() async {
    try {
      isLoadingAnalytics.value = true;

      // Fetch restaurant growth data (registrations over time)
      await _fetchRestaurantGrowthData();

      // Fetch loyalty program usage data
      await _fetchLoyaltyUsageData();

      // Fetch revenue breakdown data
      await fetchDetailedRevenueData();

      // Fetch claim activity by day data
      await _fetchClaimActivityByDayData();

      isLoadingAnalytics.value = false;
    } catch (e) {
      isLoadingAnalytics.value = false;
      if (kDebugMode) {
        print('Error fetching analytics data: $e');
      }
    }
  }

  // Helper method to fetch restaurant growth data
  Future<void> _fetchRestaurantGrowthData() async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> growthData = [];

      // Get data for the last 6 months
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(month.year, month.month + 1, 1);

        final restaurantsSnapshot = await _firestore
            .collection('restaurants')
            .where('createdAt', isLessThan: Timestamp.fromDate(nextMonth))
            .get();

        growthData.add({
          'date': month,
          'value': restaurantsSnapshot.docs.length,
        });
      }

      restaurantGrowthData.assignAll(growthData);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching restaurant growth data: $e');
      }
      rethrow;
    }
  }

  // Helper method to fetch loyalty usage data
  Future<void> _fetchLoyaltyUsageData() async {
    try {
      // Get all claims
      final claimsSnapshot = await _firestore.collection('claims').get();

      // Group claims by restaurant
      Map<String, int> restaurantClaims = {};
      for (var doc in claimsSnapshot.docs) {
        final restaurantName =
            doc.data()['restaurantName'] as String? ?? 'Unknown';
        restaurantClaims[restaurantName] =
            (restaurantClaims[restaurantName] ?? 0) + 1;
      }

      // Sort restaurants by number of claims
      final sortedRestaurants = restaurantClaims.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Take top 5 restaurants, combine others
      List<Map<String, dynamic>> usageData = [];
      int othersCount = 0;

      for (int i = 0; i < sortedRestaurants.length; i++) {
        if (i < 4) {
          // Top 4 restaurants
          usageData.add({
            'category': sortedRestaurants[i].key,
            'value': sortedRestaurants[i].value,
          });
        } else {
          // Combine the rest as "Others"
          othersCount += sortedRestaurants[i].value;
        }
      }

      if (othersCount > 0) {
        usageData.add({
          'category': 'Others',
          'value': othersCount,
        });
      }

      loyaltyUsageData.assignAll(usageData);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching loyalty usage data: $e');
      }
      rethrow;
    }
  }

  // Helper method to fetch claim activity by day data
  Future<void> _fetchClaimActivityByDayData() async {
    try {
      final claimsSnapshot = await _firestore.collection('claims').get();

      // Initialize counts for each day of the week
      Map<int, int> dayCount = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

      // Count claims by day of week
      for (var doc in claimsSnapshot.docs) {
        final timestamp = doc.data()['claimDate'] as Timestamp?;
        if (timestamp != null) {
          final dayOfWeek = timestamp.toDate().weekday % 7; // 0-6, Sunday is 0
          dayCount[dayOfWeek] = (dayCount[dayOfWeek] ?? 0) + 1;
        }
      }

      // Convert to list for chart
      List<Map<String, dynamic>> activityData = [
        {'day': 'Mon', 'count': dayCount[1] ?? 0},
        {'day': 'Tue', 'count': dayCount[2] ?? 0},
        {'day': 'Wed', 'count': dayCount[3] ?? 0},
        {'day': 'Thu', 'count': dayCount[4] ?? 0},
        {'day': 'Fri', 'count': dayCount[5] ?? 0},
        {'day': 'Sat', 'count': dayCount[6] ?? 0},
        {'day': 'Sun', 'count': dayCount[0] ?? 0},
      ];

      claimActivityByDayData.assignAll(activityData);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching claim activity by day: $e');
      }
      rethrow;
    }
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
}
