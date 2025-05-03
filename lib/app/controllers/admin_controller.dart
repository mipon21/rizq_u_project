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

  @override
  void onInit() {
    super.onInit();
    // Check if user is already logged in as admin
    checkAdminAuth();
    // Load subscription plan prices
    loadPlanPrices();
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

  // Update subscription plan price
  Future<void> updatePlanPrice(String planCode, double newPrice) async {
    try {
      // Update price in Firestore
      await _firestore.collection('subscription_plans').doc('default').update({
        planCode: newPrice,
        'updatedAt': Timestamp.now(),
      });

      // Update local observable
      planPrices[planCode] = newPrice;

      // Refresh total plan prices
      loadPlanPrices();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating plan price: $e');
      }
      throw 'Failed to update price: $e';
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

  // Fetch all loyalty program-related data
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

  // Fetch all analytics data for dashboard
  Future<void> fetchAnalyticsData() async {
    isLoadingAnalytics.value = true;
    try {
      await Future.wait([
        fetchRestaurantGrowthData(),
        fetchLoyaltyUsageData(),
        fetchRevenueBreakdownData(),
        fetchClaimActivityByDay(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching analytics data: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to load analytics data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingAnalytics.value = false;
    }
  }

  // Fetch restaurant growth over the last 6 months
  Future<void> fetchRestaurantGrowthData() async {
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

  // Fetch loyalty program usage by top restaurants
  Future<void> fetchLoyaltyUsageData() async {
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

  // Fetch revenue breakdown by subscription plans
  Future<void> fetchRevenueBreakdownData() async {
    try {
      final subscriptionsSnapshot =
          await _firestore.collection('subscriptions').get();

      // Group by plan type
      Map<String, double> planRevenue = {};
      double totalRevenue = 0;

      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        final planType = data['planType'] as String? ?? 'Unknown';
        final amount = (data['amountPaid'] as num?)?.toDouble() ?? 0.0;

        planRevenue[planType] = (planRevenue[planType] ?? 0.0) + amount;
        totalRevenue += amount;
      }

      // Convert to percentage
      List<Map<String, dynamic>> revenueData = [];
      for (var entry in planRevenue.entries) {
        final percentage =
            totalRevenue > 0 ? (entry.value / totalRevenue) * 100 : 0.0;
        revenueData.add({
          'plan': entry.key,
          'percentage': double.parse(percentage.toStringAsFixed(1)),
        });
      }

      revenueBreakdownData.assignAll(revenueData);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching revenue breakdown data: $e');
      }
      rethrow;
    }
  }

  // Fetch claim activity by day of week
  Future<void> fetchClaimActivityByDay() async {
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
}
