import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:rizq/app/utils/constants/sizes.dart';

class SubscriptionPage extends GetView<RestaurantController> {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
        elevation: 0,
        backgroundColor: MColors.primary.withOpacity(0.02),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: MColors.primary,
          ),
          tooltip: 'Back',
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingProfile.value &&
            controller.restaurantProfile.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: MColors.primary,
            ),
          );
        }

        final profile = controller.restaurantProfile.value;
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Could not load subscription details',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  onPressed: () => controller.fetchRestaurantProfile(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Determine status colors and text
        Color statusColor = Colors.grey;
        String statusText = profile.subscriptionStatus.capitalizeFirst ??
            profile.subscriptionStatus;
        IconData statusIcon = Icons.info_outline;

        if (profile.isSubscriptionActive) {
          if (profile.subscriptionStatus == 'free_trial') {
            statusColor = Colors.orange;
            statusIcon = Icons.star_outline;
            statusText = 'Free Trial';
          } else {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle_outline;
            statusText = 'Active';
          }
        } else if (profile.subscriptionStatus == 'inactive') {
          statusColor = Colors.red;
          statusIcon = Icons.cancel_outlined;
          statusText = 'Inactive';
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchRestaurantProfile(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            children: [
              const SizedBox(height: 16),
              _buildStatusCard(
                  context, profile, statusColor, statusText, statusIcon),
              const SizedBox(height: 24),
              _buildUsageCard(context, profile),
              const SizedBox(height: 24),
              _buildSubscriptionPlans(context, profile),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusCard(BuildContext context, RestaurantProfileModel profile,
      Color statusColor, String statusText, IconData statusIcon) {
    String endDateText = '';
    if (profile.subscriptionStatus == 'free_trial') {
      endDateText = '${profile.remainingTrialDays} days remaining';
    } else if (profile.subscriptionStatus == 'active' &&
        profile.subscriptionEnd != null) {
      endDateText =
          'Ends on ${DateFormat('MMM d, yyyy').format(profile.subscriptionEnd!)}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(MSizes.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (endDateText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              endDateText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageCard(BuildContext context, RestaurantProfileModel profile) {
    // Calculate scan limit based on plan
    int scanLimit = 0;
    double usagePercentage = 0.0;

    if (profile.subscriptionPlan == 'plan_100') {
      scanLimit = 100;
      usagePercentage = profile.currentScanCount / 100;
    } else if (profile.subscriptionPlan == 'plan_250') {
      scanLimit = 250;
      usagePercentage = profile.currentScanCount / 250;
    } else if (profile.subscriptionPlan == 'plan_unlimited') {
      scanLimit = -1; // unlimited
      usagePercentage = 0.0;
    } else {
      // Free trial
      scanLimit = 100;
      usagePercentage = profile.currentScanCount / 100;
    }

    // Prevent overflow for percentage indicator
    if (usagePercentage > 1.0) usagePercentage = 1.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MSizes.cardRadiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            _buildMetricContainer(
              context,
              icon: Icons.qr_code_scanner,
              title: 'Total Scans',
              value: profile.currentScanCount.toString(),
              color: MColors.primary,
            ),
            const SizedBox(height: 16),
            _buildMetricContainer(
              context,
              icon: Icons.card_giftcard,
              title: 'Rewards Issued',
              value: profile.rewardsIssued.toString(),
              color: Colors.orange,
            ),
            if (scanLimit > 0) ...[
              const SizedBox(height: 24),
              Text(
                'Scan Usage',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 12),
              LinearPercentIndicator(
                animation: true,
                lineHeight: 12.0,
                animationDuration: 1500,
                percent: usagePercentage,
                center: Text(
                  "${(usagePercentage * 100).toInt()}%",
                  style: const TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                barRadius: const Radius.circular(16),
                progressColor: _getProgressColor(usagePercentage),
                backgroundColor: Colors.grey.withOpacity(0.2),
              ),
              const SizedBox(height: 8),
              Text(
                "${profile.currentScanCount} / $scanLimit scans used",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricContainer(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(MSizes.borderRadiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans(
      BuildContext context, RestaurantProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Plans',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          context,
          name: 'Basic',
          description: 'For small businesses',
          features: [
            'Up to 100 customer scans',
            'Basic analytics',
            'Email support'
          ],
          price: '\$99.99',
          planCode: 'plan_100',
          isCurrentPlan: profile.subscriptionPlan == 'plan_100',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          context,
          name: 'Standard',
          description: 'Most popular choice',
          features: [
            'Up to 250 customer scans',
            'Enhanced analytics',
            'Priority email support',
            'Custom branding'
          ],
          price: '\$199.99',
          planCode: 'plan_250',
          isCurrentPlan: profile.subscriptionPlan == 'plan_250',
          color: Colors.green,
          isRecommended: true,
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          context,
          name: 'Premium',
          description: 'For growing businesses',
          features: [
            'Unlimited customer scans',
            'Advanced analytics & reporting',
            'Priority support',
            'API access',
            'Dedicated account manager'
          ],
          price: '\$299.99',
          planCode: 'plan_unlimited',
          isCurrentPlan: profile.subscriptionPlan == 'plan_unlimited',
          color: MColors.primary,
        ),
        const SizedBox(height: 24),
        if (!profile.isSubscriptionActive) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Renew Subscription'),
              onPressed: () => _showSubscriptionDialog(context, profile),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: MColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else if (profile.isTrialActive) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade Plan'),
              onPressed: () => _showSubscriptionDialog(context, profile),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: MColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Change Plan'),
              onPressed: () => _showSubscriptionDialog(context, profile),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: MColors.primary,
                side: const BorderSide(color: MColors.primary),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String name,
    required String description,
    required List<String> features,
    required String price,
    required String planCode,
    required bool isCurrentPlan,
    required Color color,
    bool isRecommended = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: isCurrentPlan ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MSizes.cardRadiusMd),
            side: isCurrentPlan
                ? BorderSide(color: color, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '/month',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Current Plan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isRecommended)
          Positioned(
            top: -12,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showSubscriptionDialog(
      BuildContext context, RestaurantProfileModel profile) {
    // For demonstration, show a mock subscription dialog
    // In a real app, this would connect to a payment processing service
    Get.dialog(
      AlertDialog(
        title: const Text('Change Subscription Plan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This feature will be available soon. In the production app, this would connect to a payment gateway to process subscription changes.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Icon(
              Icons.payments_outlined,
              size: 48,
              color: Colors.grey,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Coming Soon',
                'Subscription management will be available in a future update.',
                backgroundColor: MColors.info.withOpacity(0.9),
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  String _getPlanDescription(String planCode) {
    switch (planCode) {
      case 'plan_100':
        return 'Basic Plan - Up to 100 scans';
      case 'plan_250':
        return 'Standard Plan - Up to 250 scans';
      case 'plan_unlimited':
        return 'Premium Plan - Unlimited scans';
      case 'free_trial':
        return 'Free Trial - Up to 100 scans';
      default:
        return 'Custom Plan';
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 0.7) return Colors.green;
    if (percentage < 0.9) return Colors.orange;
    return Colors.red;
  }
}
