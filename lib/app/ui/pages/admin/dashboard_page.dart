import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/constants/colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../ui/theme/widget_themes/admin_notification_panel.dart';

class AdminDashboardPage extends GetView<AdminController> {
  const AdminDashboardPage({Key? key}) : super(key: key);

  // Override the controller getter to ensure it's properly initialized
  @override
  AdminController get controller {
    if (!Get.isRegistered<AdminController>()) {
      Get.put(AdminController(), permanent: true);
    }
    return Get.find<AdminController>();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch dashboard metrics on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchDashboardMetrics();
      controller.fetchLoyaltyProgramData();
      // Pre-fetch analytics data for faster display when user opens the panel
      controller.fetchAnalyticsData();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
        ),
        backgroundColor: MColors.primary,
        actions: [
          // Replace badges with a simple Stack for notification indicator
          Obx(() => Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _showNotificationsPanel(context),
                    tooltip: 'Notifications',
                  ),
                  if (controller.unreadNotifications.value > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          controller.unreadNotifications.value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              )),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalyticsPanel(context),
            tooltip: 'Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.fetchDashboardMetrics();
              controller.fetchLoyaltyProgramData();
              controller.fetchAnalyticsData();
              Get.snackbar(
                'Refreshing Data',
                'Dashboard data is being updated...',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
              );
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActions(),
            const SizedBox(height: 24),

            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 24),

            // Add loyalty program section
            const Text(
              'Loyalty Program Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLoyaltyMetrics(),
            const SizedBox(height: 24),

            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(),

            // Add pending approvals section
            const SizedBox(height: 24),
            _buildPendingApprovalsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.restaurant_menu,
                    label: 'Add Restaurant',
                    onPressed: () => Get.toNamed(Routes.ADMIN_RESTAURANTS),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.people,
                    label: 'Manage Customers',
                    onPressed: () => Get.toNamed(Routes.ADMIN_CUSTOMERS),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.attach_money,
                    label: 'Update Pricing',
                    onPressed: () => Get.toNamed(Routes.ADMIN_PLAN_PRICING),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.bar_chart,
                    label: 'View Reports',
                    onPressed: () => Get.toNamed(Routes.ADMIN_REPORTS),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => _buildActionButton(
                        icon: Icons.approval,
                        label:
                            'Pending Approvals (${controller.pendingApprovals})',
                        onPressed: () => _showPendingApprovals(),
                        color: controller.pendingApprovals.value > 0
                            ? Colors.orange
                            : Colors.blue,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? MColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: MColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              Get.back(); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('Restaurants'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_RESTAURANTS);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Customers'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_CUSTOMERS);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Subscriptions'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_SUBSCRIPTIONS);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_REPORTS);
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Plan Pricing'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_PLAN_PRICING);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => controller.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Obx(() => GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildStatCard(
              title: 'Total Restaurants',
              value: controller.totalRestaurants.toString(),
              icon: Icons.restaurant,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Total Customers',
              value: controller.totalCustomers.toString(),
              icon: Icons.people,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Active Subscriptions',
              value: controller.activeSubscriptions.toString(),
              icon: Icons.verified,
              color: Colors.purple,
            ),
            _buildStatCard(
              title: 'Total Revenue',
              value: '\$${controller.totalRevenue.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.orange,
            ),
          ],
        ));
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildLoyaltyMetrics() {
    return Obx(() {
      if (controller.isLoadingLoyaltyData.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Loyalty Programs',
                  value: '${controller.loyaltyPrograms.length}',
                  icon: Icons.card_giftcard,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Rewards Claimed',
                  value: '${controller.totalRewardsClaimed}',
                  icon: Icons.redeem,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Recent Reward Claims',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.recentClaims.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text('No recent reward claims'),
                      ),
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.recentClaims.length > 5
                            ? 5
                            : controller.recentClaims.length,
                        itemBuilder: (context, index) {
                          final claim = controller.recentClaims[index];
                          final timestamp =
                              (claim['claimDate'] as Timestamp?)?.toDate();
                          final formattedDate = timestamp != null
                              ? DateFormat('MMM d, yyyy - HH:mm')
                                  .format(timestamp)
                              : 'Unknown';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple[100],
                              child: const Icon(
                                Icons.redeem,
                                color: Colors.deepPurple,
                              ),
                            ),
                            title: Text(
                              '${claim['restaurantName']} - ${claim['rewardType']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Claimed on $formattedDate'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Navigate to detailed view or show dialog
                              _showClaimDetails(context, claim);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (controller.recentClaims.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Navigate to reports page
                          Get.toNamed(Routes.ADMIN_REPORTS);
                        },
                        child: const Text('View All'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showClaimDetails(BuildContext context, Map<String, dynamic> claim) {
    final timestamp = (claim['claimDate'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null
        ? DateFormat('MMMM d, yyyy - HH:mm').format(timestamp)
        : 'Unknown';

    Get.dialog(
      AlertDialog(
        title: const Text('Reward Claim Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Restaurant', claim['restaurantName'] ?? 'Unknown'),
            _buildDetailRow('Reward', claim['rewardType'] ?? 'Unknown'),
            _buildDetailRow('Customer ID', claim['customerId'] ?? 'Unknown'),
            _buildDetailRow('Points Used', '${claim['pointsUsed'] ?? 0}'),
            _buildDetailRow('Claimed On', formattedDate),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      height: 130,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Latest System Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              // height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  // This would typically be populated with real data
                  IconData icon;
                  String title;
                  String subtitle;
                  Color color;

                  switch (index) {
                    case 0:
                      icon = Icons.restaurant_menu;
                      title = 'New Restaurant Registration';
                      subtitle = '2 minutes ago';
                      color = Colors.blue;
                      break;
                    case 1:
                      icon = Icons.person_add;
                      title = 'New Customer Account';
                      subtitle = '15 minutes ago';
                      color = Colors.green;
                      break;
                    case 2:
                      icon = Icons.card_giftcard;
                      title = 'New Loyalty Program Created';
                      subtitle = '1 hour ago';
                      color = Colors.purple;
                      break;
                    case 3:
                      icon = Icons.payment;
                      title = 'Subscription Payment Received';
                      subtitle = '3 hours ago';
                      color = Colors.orange;
                      break;
                    case 4:
                      icon = Icons.notifications;
                      title = 'System Update Completed';
                      subtitle = 'Today, 09:30 AM';
                      color = Colors.red;
                      break;
                    default:
                      icon = Icons.info;
                      title = 'System Activity';
                      subtitle = 'Unknown time';
                      color = Colors.grey;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(title),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Notifications panel
  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return AdminNotificationPanel(isBottomSheet: true);
          },
        );
      },
    );
  }

  // Pending approvals section
  Widget _buildPendingApprovalsSection() {
    return Obx(() {
      if (controller.pendingApprovals.value == 0) {
        return const SizedBox.shrink(); // Don't show if no pending approvals
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Approvals (${controller.pendingApprovals})',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showPendingApprovals(),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '${controller.pendingApprovals} restaurants waiting for approval',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'New restaurant registrations require your approval before they can start using the platform.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showPendingApprovals(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Review Pending Approvals'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showPendingApprovals() {
    Get.toNamed(Routes.ADMIN_RESTAURANTS);
  }

  // Analytics panel
  void _showAnalyticsPanel(BuildContext context) {
    // Fetch analytics data when opening the panel
    controller.fetchAnalyticsData();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Analytics Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingAnalytics.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView(
                    controller: scrollController,
                    children: [
                      _buildAnalyticsSection(
                        title: 'Restaurant Growth',
                        child: SizedBox(
                          height: 300,
                          child: _buildRestaurantGrowthChart(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildAnalyticsSection(
                        title: 'Loyalty Program Usage',
                        child: SizedBox(
                          height: 300,
                          child: _buildLoyaltyUsageChart(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildAnalyticsSection(
                        title: 'Revenue Breakdown',
                        child: SizedBox(
                          height: 300,
                          child: _buildRevenueBreakdownChart(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildAnalyticsSection(
                        title: 'Claim Activity by Day',
                        child: SizedBox(
                          height: 300,
                          child: _buildClaimActivityChart(),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(
      {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildRestaurantGrowthChart() {
    // Convert controller data to GrowthData objects
    final List<GrowthData> growthData = controller.restaurantGrowthData
        .map((data) => GrowthData(
              data['date'] as DateTime,
              data['value'] as int,
            ))
        .toList();

    // Display fallback data if no data is available
    if (growthData.isEmpty) {
      final now = DateTime.now();
      return SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat.MMM(),
          intervalType: DateTimeIntervalType.months,
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Number of Restaurants'),
        ),
        series: <CartesianSeries>[
          SplineSeries<GrowthData, DateTime>(
            name: 'Restaurant Growth',
            dataSource: [
              GrowthData(DateTime(now.year, now.month - 5, 1), 0),
              GrowthData(DateTime(now.year, now.month, 1), 0),
            ],
            xValueMapper: (GrowthData data, _) => data.date,
            yValueMapper: (GrowthData data, _) => data.value,
            color: Colors.grey,
          ),
        ],
        annotations: [
          CartesianChartAnnotation(
            widget: Container(
              child: const Text(
                'No data available',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            coordinateUnit: CoordinateUnit.point,
            x: DateTime(now.year, now.month - 2, 15),
            y: 0,
          ),
        ],
      );
    }

    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat.MMM(),
        intervalType: DateTimeIntervalType.months,
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Number of Restaurants'),
      ),
      legend: Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        SplineSeries<GrowthData, DateTime>(
          name: 'Restaurant Growth',
          dataSource: growthData,
          xValueMapper: (GrowthData data, _) => data.date,
          yValueMapper: (GrowthData data, _) => data.value,
          color: Colors.blue,
          markerSettings: const MarkerSettings(isVisible: true),
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
      ],
    );
  }

  Widget _buildLoyaltyUsageChart() {
    // Convert controller data to LoyaltyUsageData objects
    final List<LoyaltyUsageData> usageData = controller.loyaltyUsageData
        .map((data) => LoyaltyUsageData(
              data['category'] as String,
              data['value'] as int,
            ))
        .toList();

    // Display fallback message if no data is available
    if (usageData.isEmpty) {
      return const Center(
        child: Text(
          'No loyalty usage data available',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SfCircularChart(
      legend: Legend(
        isVisible: true,
        position: LegendPosition.right,
      ),
      series: <CircularSeries>[
        PieSeries<LoyaltyUsageData, String>(
          dataSource: usageData,
          xValueMapper: (LoyaltyUsageData data, _) => data.category,
          yValueMapper: (LoyaltyUsageData data, _) => data.value,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
          ),
          enableTooltip: true,
          explode: true,
          explodeIndex: 0,
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdownChart() {
    // Convert controller data to RevenueData objects
    final List<RevenueData> revenueData = controller.revenueBreakdownData
        .map((data) => RevenueData(
              data['plan'] as String,
              data['percentage'] as double,
            ))
        .toList();

    // Display fallback message if no data is available
    if (revenueData.isEmpty) {
      return const Center(
        child: Text(
          'No revenue data available',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Find maximum percentage for y-axis scaling
    double maxPercentage = 0;
    for (var data in revenueData) {
      if (data.percentage > maxPercentage) {
        maxPercentage = data.percentage;
      }
    }

    // Round up to nearest 10
    maxPercentage = (maxPercentage / 10).ceil() * 10.0;

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Revenue %'),
        minimum: 0,
        maximum: maxPercentage,
      ),
      series: <CartesianSeries>[
        ColumnSeries<RevenueData, String>(
          dataSource: revenueData,
          xValueMapper: (RevenueData data, _) => data.plan,
          yValueMapper: (RevenueData data, _) => data.percentage,
          borderRadius: BorderRadius.circular(5),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
          ),
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade700],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ],
    );
  }

  Widget _buildClaimActivityChart() {
    // Convert controller data to ActivityData objects
    final List<ActivityData> activityData = controller.claimActivityByDayData
        .map((data) => ActivityData(
              data['day'] as String,
              data['count'] as int,
            ))
        .toList();

    // Display fallback message if no data is available
    if (activityData.isEmpty) {
      return const Center(
        child: Text(
          'No claim activity data available',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Number of Claims'),
      ),
      series: <CartesianSeries>[
        SplineAreaSeries<ActivityData, String>(
          dataSource: activityData,
          xValueMapper: (ActivityData data, _) => data.day,
          yValueMapper: (ActivityData data, _) => data.count,
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.3),
              Colors.purple.withOpacity(0.1)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderColor: Colors.purple,
          borderWidth: 2,
        ),
      ],
    );
  }
}

// Models for chart data
class ChartData {
  final String month;
  final int restaurants;
  final int customers;

  ChartData(this.month, this.restaurants, this.customers);
}

class PieChartData {
  final String plan;
  final double percentage;
  final Color color;

  PieChartData(this.plan, this.percentage, this.color);
}

// Additional models for analytics charts
class GrowthData {
  final DateTime date;
  final int value;

  GrowthData(this.date, this.value);
}

class LoyaltyUsageData {
  final String category;
  final int value;

  LoyaltyUsageData(this.category, this.value);
}

class RevenueData {
  final String plan;
  final double percentage;

  RevenueData(this.plan, this.percentage);
}

class ActivityData {
  final String day;
  final int count;

  ActivityData(this.day, this.count);
}
