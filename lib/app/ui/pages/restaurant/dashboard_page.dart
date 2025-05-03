import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust import
import 'package:rizq/app/controllers/restaurant_controller.dart'; // Adjust import
import 'package:rizq/app/routes/app_pages.dart'; // Adjust import
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final RestaurantController controller = Get.find<RestaurantController>();
  final AuthController authController = Get.find<AuthController>();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // Always initialize with empty data first
    if (controller.restaurantProfile.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchRestaurantProfile();
        controller.fetchClaimedRewards();
      });
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
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
                )
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
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

  Widget _buildHomeTab() {
    return GetBuilder<RestaurantController>(
      builder: (_) => Obx(() {
        // Show loading indicator while fetching
        if (controller.isLoadingProfile.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = controller.restaurantProfile.value;

        // Force refresh if value is null in release mode
        if (profile == null) {
          // Log the issue - in release mode we want to show this
          print('Profile is null - forcing refresh...');

          // Use a FutureBuilder to handle the loading state
          return FutureBuilder(
            future: controller.fetchRestaurantProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // After fetching, check if profile is still null
              if (controller.restaurantProfile.value == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 60, color: Colors.orange),
                      const SizedBox(height: 20),
                      const Text('Could not load restaurant profile.',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () =>
                            Get.toNamed(Routes.RESTAURANT_PROFILE_SETUP),
                        child: const Text('Setup Profile'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => controller.fetchRestaurantProfile(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else {
                // Profile was fetched successfully, force UI update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.update();
                });
                return _buildDashboardContent(
                    controller.restaurantProfile.value!);
              }
            },
          );
        }

        // Display Dashboard Content
        return _buildDashboardContent(profile);
      }),
    );
  }

  // Extract dashboard content to separate method to avoid duplication
  Widget _buildDashboardContent(RestaurantProfileModel profile) {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.fetchRestaurantProfile();
        return Future.value();
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Welcome Message or Trial Info
          _buildTrialInfoCard(context, profile),
          if (profile.isTrialActive) const SizedBox(height: 16),

          // Stat Cards
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    _buildStatCard(
                        context,
                        'Total Scans',
                        controller.scanCount.toString(),
                        Icons.qr_code_scanner,
                      ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      context,
                      'Rewards Issued',
                      controller.rewardsIssuedCount.toString(),
                      Icons.card_giftcard,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                'Subscription',
                profile.subscriptionStatus.capitalizeFirst ??
                    profile.subscriptionStatus,
                Icons.star_border,
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProgramSettingsTab() {
    return Obx(() {
      if (controller.isLoadingProfile.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final profile = controller.restaurantProfile.value;
      if (profile == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please complete your profile setup first'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.toNamed(Routes.RESTAURANT_PROFILE_SETUP),
                child: const Text('Setup Profile'),
              ),
            ],
          ),
        );
      }

      // This is the actual program settings content
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loyalty Program Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Program',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow('Points per Scan', '1 point'),
                    _buildInfoRow('Reward Threshold', '10 points'),
                    _buildInfoRow(
                      'Reward Type',
                      'Standard Reward',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.toNamed(Routes.RESTAURANT_PROGRAM_CONFIG),
                        child: const Text('Edit Program Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSubscriptionTab() {
    // This would be your subscription content
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Subscription', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.toNamed(Routes.RESTAURANT_SUBSCRIPTION),
            child: const Text('Manage Subscription'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Obx(() {
      if (controller.isLoadingProfile.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final profile = controller.restaurantProfile.value;
      if (profile == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please complete your profile setup'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.toNamed(Routes.RESTAURANT_PROFILE_SETUP),
                child: const Text('Setup Profile'),
              ),
            ],
          ),
        );
      }

      // This is the actual profile content
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: profile.logoUrl.isNotEmpty
                  ? NetworkImage(profile.logoUrl)
                  : null,
              child: profile.logoUrl.isEmpty
                  ? const Icon(Icons.restaurant, size: 50)
                  : null,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurant Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow('Name', profile.name),
                    _buildInfoRow('Address', profile.address),
                    _buildInfoRow('User ID', profile.uid),
                    _buildInfoRow(
                      'Member Since',
                      DateFormat('MMMM dd, yyyy').format(profile.createdAt),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.toNamed(Routes.RESTAURANT_PROFILE_SETUP),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Subscription Plan Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Plan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Current Plan',
                      _formatPlanName(profile.subscriptionPlan),
                    ),
                    _buildInfoRow(
                      'Status',
                      profile.subscriptionStatus.capitalizeFirst ??
                          profile.subscriptionStatus,
                      valueColor: _getStatusColor(profile.subscriptionStatus),
                    ),
                    if (profile.isTrialActive)
                      _buildInfoRow(
                        'Trial Remaining',
                        '${profile.remainingTrialDays} days',
                        valueColor: Colors.orange[800],
                      ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Scans Used',
                      '${profile.currentScanCount} scans',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.toNamed(Routes.RESTAURANT_SUBSCRIPTION),
                        child: const Text('Manage Subscription'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
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
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPlanName(String planCode) {
    switch (planCode) {
      case 'free_trial':
        return 'Free Trial';
      case 'plan_100':
        return 'Basic (100 Scans)';
      case 'plan_250':
        return 'Standard (250 Scans)';
      case 'plan_unlimited':
        return 'Premium (Unlimited)';
      default:
        return planCode;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'free_trial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRewardsTab() {
    final TextEditingController codeController = TextEditingController();

    return GetBuilder<RestaurantController>(
      builder: (_) => Obx(() {
        if (controller.isLoadingClaims.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Verification Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verify Customer Reward',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter the 6-digit claim code shown on customer\'s reward',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeController,
                          decoration: InputDecoration(
                            hintText: 'Enter 6-digit code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 18,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLength: 6,
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: controller.isVerifying.value
                            ? null
                            : () {
                                if (codeController.text.length == 6) {
                                  controller
                                      .verifyRewardClaim(codeController.text);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 15),
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: controller.isVerifying.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('VERIFY'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Verification Result Message
                  if (controller.showVerificationResult.value)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: controller.verificationResult.value
                                .startsWith('Success')
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: controller.verificationResult.value
                                  .startsWith('Success')
                              ? Colors.green[300]!
                              : Colors.orange[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                controller.verificationResult.value
                                        .startsWith('Success')
                                    ? Icons.check_circle
                                    : Icons.info,
                                color: controller.verificationResult.value
                                        .startsWith('Success')
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.verificationResult.value,
                                  style: TextStyle(
                                    color: controller.verificationResult.value
                                            .startsWith('Success')
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                controller.clearVerificationResult();
                                codeController.clear();
                              },
                              child: const Text('DISMISS'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Separator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Reward History',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),

            // Rewards History List
            Expanded(
              child: controller.claimedRewards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No rewards claimed yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Once customers claim rewards, they will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => controller.fetchClaimedRewards(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.fetchClaimedRewards(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.claimedRewards.length,
                        itemBuilder: (context, index) {
                          final reward = controller.claimedRewards[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.purple[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          reward.isVerified
                                              ? Icons.verified
                                              : Icons.redeem,
                                          color: reward.isVerified
                                              ? Colors.green[700]
                                              : Colors.purple[800],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  reward.rewardType,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    '${reward.pointsUsed} points',
                                                    style: TextStyle(
                                                      color: Colors.green[800],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  reward.formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Container(
                                      //   padding: const EdgeInsets.symmetric(
                                      //     horizontal: 10,
                                      //     vertical: 6,
                                      //   ),
                                      //   decoration: BoxDecoration(
                                      //     color: Colors.green[100],
                                      //     borderRadius: BorderRadius.circular(20),
                                      //   ),
                                      //   child: Text(
                                      //     '${reward.pointsUsed} points',
                                      //     style: TextStyle(
                                      //       color: Colors.green[800],
                                      //       fontWeight: FontWeight.bold,
                                      //       fontSize: 12,
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Customer ID: ${reward.customerId.substring(0, 8)}...',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            'Claim Code:',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple[800],
                                            ),
                                          ),
                                          Text(
                                            reward.verificationCode,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Verification status
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: reward.isVerified
                                          ? Colors.green[50]
                                          : Colors.orange[50],
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: reward.isVerified
                                            ? Colors.green[300]!
                                            : Colors.orange[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          reward.isVerified
                                              ? Icons.verified_user
                                              : Icons.pending_outlined,
                                          size: 16,
                                          color: reward.isVerified
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            reward.isVerified
                                                ? 'Verified on ${reward.formattedVerifiedDate}'
                                                : 'Not verified - Waiting for customer to redeem',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: reward.isVerified
                                                  ? Colors.green[700]
                                                  : Colors.orange[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (!reward.isVerified)
                                          TextButton(
                                            onPressed: () {
                                              codeController.text =
                                                  reward.verificationCode;
                                              // Auto-scroll to top
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 100), () {
                                                // Use Scrollable.ensureVisible or other scrolling method
                                              });
                                            },
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text('VERIFY NOW'),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force controller update when building
    controller.update();

    final List<Widget> _pages = [
      _buildHomeTab(),
      _buildProgramSettingsTab(),
      const SizedBox(), // Placeholder for FAB
      _buildRewardsTab(), // This is now index 3
      _buildProfileTab(), // This is now index 4
      _buildRewardsTab(), // Duplicate for index 5
    ];

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.name.isNotEmpty
              ? controller.name
              : _currentIndex == 0
                  ? 'Dashboard'
                  : _currentIndex == 1
                      ? 'Program Settings'
                      : _currentIndex == 3
                          ? 'Rewards History'
                          : _currentIndex == 4
                              ? 'Profile'
                              : 'Dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: _pages[
          _currentIndex == 2 ? 0 : _currentIndex], // Skip dummy FAB index
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(Routes.RESTAURANT_QR_SCANNER),
        child: const Icon(Icons.qr_code_scanner),
        tooltip: 'Scan Customer QR',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _currentIndex == 0
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Home',
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),

              // Program Settings
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: _currentIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Program Settings',
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                  // No navigation, just switch tabs
                },
              ),

              // Space for FAB
              const SizedBox(width: 40),

              // Rewards History
              IconButton(
                icon: Icon(
                  Icons.card_giftcard_outlined,
                  color: _currentIndex == 3
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Rewards History',
                onPressed: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                  controller
                      .fetchClaimedRewards(); // Refresh rewards when tab is selected
                },
              ),

              // Profile
              IconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: _currentIndex == 4
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Edit Profile',
                onPressed: () {
                  setState(() {
                    _currentIndex = 4;
                  });
                  // No navigation, just switch tabs
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
