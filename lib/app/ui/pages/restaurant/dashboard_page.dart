import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust import
import 'package:rizq/app/controllers/restaurant_controller.dart'; // Adjust import
import 'package:rizq/app/routes/app_pages.dart'; // Adjust import

class DashboardPage extends GetView<RestaurantController> {
  const DashboardPage({Key? key}) : super(key: key);

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialInfoCard(
    BuildContext context,
    RestaurantProfileModel profile,
  ) {
    if (!profile.isTrialActive) return const SizedBox.shrink();
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              "Free Trial active! ${profile.remainingTrialDays} days left.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () =>
              Text(controller.name.isNotEmpty ? controller.name : 'Dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingProfile.value &&
            controller.restaurantProfile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = controller.restaurantProfile.value;
        if (profile == null) {
          // Handle case where profile is loaded but null (e.g., error or new user?)
          // Might need a button to go to profile setup if name is empty
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Could not load restaurant profile.'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Get.toNamed(Routes.RESTAURANT_PROFILE_SETUP),
                  child: const Text('Setup Profile'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => controller.fetchRestaurantProfile(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Display Dashboard Content
        return RefreshIndicator(
          onRefresh: () => controller.fetchRestaurantProfile(),
          child: ListView(
            // Use ListView for scrollability
            padding: const EdgeInsets.all(16.0),
            children: [
              // Welcome Message or Trial Info
              _buildTrialInfoCard(context, profile),
              if (profile.isTrialActive) const SizedBox(height: 16),

              // Stat Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Scans',
                      controller.scanCount.toString(),
                      Icons.qr_code_scanner,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Rewards Issued',
                      controller.rewardsIssuedCount.toString(),
                      Icons.card_giftcard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                'Subscription',
                profile.subscriptionStatus.capitalizeFirst ??
                    profile.subscriptionStatus,
                Icons.star_border,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Wrap(
                // Use Wrap for responsiveness
                spacing: 12.0, // Horizontal space
                runSpacing: 12.0, // Vertical space
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Edit Profile'),
                    onPressed: () =>
                        Get.toNamed(Routes.RESTAURANT_PROFILE_SETUP),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 45),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Program Settings'),
                    onPressed: () =>
                        Get.toNamed(Routes.RESTAURANT_PROGRAM_CONFIG),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 45),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment_outlined),
                    label: const Text('Subscription'),
                    onPressed: () =>
                        Get.toNamed(Routes.RESTAURANT_SUBSCRIPTION),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 45),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- Placeholder for Bar Chart ---
              // Container(
              //   height: 200,
              //   child: Card(
              //     child: Padding(
              //       padding: const EdgeInsets.all(16.0),
              //       child: Center(child: Text('Monthly Scan Trends Chart (Coming Soon)')),
              //     ),
              //   ),
              // ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(Routes.RESTAURANT_QR_SCANNER),
        label: const Text('Scan Customer QR'),
        icon: const Icon(Icons.qr_code_scanner),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
