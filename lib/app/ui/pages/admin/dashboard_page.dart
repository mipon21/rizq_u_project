import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/sample_data_creator.dart';

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../ui/theme/widget_themes/admin_notification_panel.dart';
import '../../../utils/subscription_migration_helper.dart';
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
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
        ),
        backgroundColor: MColors.primary,
        actions: [
          // Nuclear Reset Button (Danger Zone)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.dangerous, color: Colors.red),
              onPressed: () => controller.cleanupAllFirebaseData(),
              tooltip: '⚠️ RESET ALL DATA (Danger Zone)',
            ),
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.fetchDashboardMetrics();
              controller.fetchLoyaltyProgramData();
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pending approvals first
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => _buildActionButton(
                        icon: Icons.approval,
                        label:
                            'Pending Approvals (${controller.pendingApprovals})',
                        onPressed: () => _showPendingApprovals(),
                        color: controller.pendingApprovals.value > 0
                            ? Colors.orange
                            : null,
                      )),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    icon: Icons.restaurant_menu,
                    label: 'Add Restaurant',
                    onPressed: () => Get.toNamed(Routes.ADMIN_RESTAURANTS),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    icon: Icons.people,
                    label: 'Manage Customers',
                    onPressed: () => Get.toNamed(Routes.ADMIN_CUSTOMERS),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    icon: Icons.subscriptions,
                    label: 'Custom Plans',
                    onPressed: () =>
                        Get.toNamed(Routes.ADMIN_CUSTOM_SUBSCRIPTION_PLANS),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    icon: Icons.bar_chart,
                    label: 'View Reports',
                    onPressed: () => Get.toNamed(Routes.ADMIN_REPORTS),
                  ),
                ),
              ],
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
      icon: Icon(
        icon,
        color: color ?? MColors.primary,
      ),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? MColors.primary,
          fontSize: 12,
        ),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: (color ?? MColors.primary).withOpacity(0.8),
        shadowColor: Colors.grey.shade200,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        side: BorderSide(color: color ?? MColors.primary, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_REPORTS);
            },
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: const Text('Custom Plans'),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(Routes.ADMIN_CUSTOM_SUBSCRIPTION_PLANS);
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
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading dashboard metrics...'),
              ],
            ),
          ),
        );
      }
      
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.0,
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
                      Obx(() => _buildStatCard(
              title: 'Total Revenue${_getRevenueModeLabel()}',
              value: '${controller.totalRevenue.toStringAsFixed(2)} MAD',
              icon: Icons.attach_money,
              color: Colors.orange,
            )),
        ],
      );
    });
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
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
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
    if (kDebugMode) {
      print('Pending Approvals button clicked');
      print('Navigating to: ${Routes.ADMIN_RESTAURANT_REGISTRATIONS}');
      print('Current pending approvals count: ${controller.pendingApprovals.value}');
    }
    
    try {
      Get.toNamed(Routes.ADMIN_RESTAURANT_REGISTRATIONS);
      if (kDebugMode) {
        print('Navigation initiated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Navigation failed: $e');
      }
      Get.snackbar(
        'Navigation Error',
        'Failed to open Restaurant Registrations: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _getRevenueModeLabel() {
    switch (controller.revenueMode.value) {
      case 'customer_only':
        return '\n(Customer Only)';
      case 'combined':
        return '\n(Combined)';
      case 'admin_value':
        return '\n(Admin Value)';
      default:
        return '';
    }
  }
}
