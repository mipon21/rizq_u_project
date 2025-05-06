import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:rizq/app/controllers/restaurant_controller.dart';
import 'package:rizq/app/utils/constants/colors.dart'; // Adjust

class SubscriptionPage extends GetView<RestaurantController> {
  const SubscriptionPage({Key? key}) : super(key: key);

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
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
          return const Center(child: CircularProgressIndicator());
        }
        final profile = controller.restaurantProfile.value;
        if (profile == null) {
          return const Center(
            child: Text('Could not load subscription details.'),
          );
        }

        // Determine colors based on status
        Color statusColor = Colors.grey;
        if (profile.isSubscriptionActive) {
          statusColor = Colors.green;
        } else if (profile.subscriptionStatus == 'inactive') {
          statusColor = Colors.red;
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchRestaurantProfile(),
          child: ListView(
            // Use ListView for potential future additions
            padding: const EdgeInsets.all(20.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        'Plan',
                        profile.subscriptionPlan.capitalizeFirst ??
                            profile.subscriptionPlan,
                      ),
                      _buildInfoRow(
                        'Status',
                        profile.subscriptionStatus.capitalizeFirst ??
                            profile.subscriptionStatus,
                        valueColor: statusColor,
                      ),
                      if (profile.subscriptionStatus == 'free_trial' &&
                          profile.trialStartDate != null)
                        _buildInfoRow(
                          'Trial Ends',
                          DateFormat.yMMMd().format(
                            profile.trialStartDate!.add(
                              const Duration(days: 60),
                            ),
                          ),
                        ),
                      if (profile.subscriptionStatus == 'free_trial' &&
                          profile.isTrialActive)
                        _buildInfoRow(
                          'Days Remaining',
                          '${profile.remainingTrialDays} days',
                          valueColor: Colors.orange[800],
                        ),
                      // Add expiry date for active plans if available in model
                      // _buildInfoRow('Next Billing Date', '...'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        'Total Scans Recorded',
                        profile.currentScanCount.toString(),
                      ),
                      _buildInfoRow(
                        'Rewards Issued',
                        profile.rewardsIssued.toString(),
                      ),
                      // Placeholder for scan limit progress bar
                      // if (profile.subscriptionPlan == 'plan_100') ...[
                      //    const SizedBox(height: 10),
                      //    LinearProgressIndicator(value: profile.currentScanCount / 100),
                      //    const SizedBox(height: 5),
                      //    Text('${profile.currentScanCount} / 100 scans used this cycle'),
                      // ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Placeholder Buttons for actions
              Center(
                child: Column(
                  children: [
                    if (!profile.isSubscriptionActive &&
                        profile.subscriptionStatus != 'free_trial')
                      ElevatedButton(
                        onPressed: () {
                          /* TODO: Implement Renew/Upgrade flow */
                          Get.snackbar(
                            'Info',
                            'Subscription management coming soon!',
                          );
                        },
                        child: const Text('Renew Subscription'),
                      ),
                    if (profile.isTrialActive || profile.isSubscriptionActive)
                      TextButton(
                        onPressed: () {
                          /* TODO: Implement Upgrade flow */
                          Get.snackbar('Info', 'Plan upgrades coming soon!');
                        },
                        child: const Text('View/Upgrade Plans'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
