import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:intl/intl.dart';

class RewardsTab extends StatelessWidget {
  final int initialTabIndex;

  const RewardsTab({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RestaurantController controller = Get.find<RestaurantController>();

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: MColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Reward Claims"),
                Tab(text: "Recent Scans"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Rewards Claims Tab
                RewardClaimsView(controller: controller),

                // Recent Scans Tab
                RecentScansView(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RewardClaimsView extends StatelessWidget {
  final RestaurantController controller;

  const RewardClaimsView({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController searchController = TextEditingController();

    return GetBuilder<RestaurantController>(
      builder: (_) => Obx(() {
        if (controller.isLoadingClaims.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter rewards based on search text
        final filteredRewards = searchController.text.isEmpty
            ? controller.claimedRewards
            : controller.claimedRewards
                .where((reward) => reward.verificationCode
                    .toLowerCase()
                    .contains(searchController.text.toLowerCase()))
                .toList();

        return Column(
          children: [
            // Verification Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Enter the 6-digit claim code shown on customer\'s reward',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: codeController,
                          decoration: InputDecoration(
                            hintText: 'Enter 6-digit code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            counterText: '',
                          ),
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLength: 6,
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Center(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: controller.isVerifying.value
                                ? null
                                : () {
                                    if (codeController.text.length == 6) {
                                      controller.verifyRewardClaim(
                                          codeController.text);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 42),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              backgroundColor: MColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: controller.isVerifying.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('VERIFY'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Verification Result Message
                  if (controller.showVerificationResult.value)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: controller.verificationResult.value
                                .startsWith('Success')
                            ? MColors.primary.withOpacity(0.1)
                            : MColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: controller.verificationResult.value
                                  .startsWith('Success')
                              ? MColors.primary.withOpacity(0.3)
                              : MColors.primary.withOpacity(0.3),
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
                                    ? MColors.primary
                                    : MColors.primary.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  controller.verificationResult.value,
                                  style: TextStyle(
                                    color: controller.verificationResult.value
                                            .startsWith('Success')
                                        ? MColors.primary
                                        : MColors.primary.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                controller.clearVerificationResult();
                                codeController.clear();
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'DISMISS',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Rewards History List with Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rewards History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Container(
                    width: 130,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 12),
                        hintText: 'Search code',
                        hintStyle:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.search,
                            size: 16, color: Colors.grey[600]),
                        prefixIconConstraints:
                            const BoxConstraints(maxWidth: 30, maxHeight: 30),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (value) {
                        // Force refresh to apply filtering
                        controller.update();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredRewards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            searchController.text.isNotEmpty
                                ? Icons.search_off
                                : Icons.card_giftcard_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchController.text.isNotEmpty
                                ? 'No matching rewards found'
                                : 'No rewards claimed yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchController.text.isNotEmpty
                                ? 'Try a different search term'
                                : 'Once customers claim rewards, they will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (searchController.text.isNotEmpty) {
                                searchController.clear();
                                controller.update();
                              } else {
                                controller.fetchClaimedRewards();
                              }
                            },
                            icon: Icon(searchController.text.isNotEmpty
                                ? Icons.clear
                                : Icons.refresh),
                            label: Text(searchController.text.isNotEmpty
                                ? 'Clear search'
                                : 'Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.fetchClaimedRewards(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredRewards.length,
                        itemBuilder: (context, index) {
                          final reward = filteredRewards[index];
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
                                          color:
                                              MColors.primary.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          reward.isVerified
                                              ? Icons.verified
                                              : Icons.redeem,
                                          color: reward.isVerified
                                              ? MColors.primary
                                              : MColors.primary,
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
                                                    color: MColors.primary
                                                        .withOpacity(0.18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    '${reward.pointsUsed} points',
                                                    style: TextStyle(
                                                      color: MColors.primary,
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
                                              color: MColors.primary,
                                            ),
                                          ),
                                          Text(
                                            reward.isVerified
                                                ? reward.verificationCode
                                                : '••••••',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: MColors.primary,
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
                                          ? MColors.primary.withOpacity(0.1)
                                          : MColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: reward.isVerified
                                            ? MColors.primary.withOpacity(0.3)
                                            : MColors.primary.withOpacity(0.3),
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
                                                ? MColors.primary
                                                : MColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            reward.isVerified
                                                ? 'Verified on ${reward.formattedVerifiedDate}'
                                                : 'Not verified - Waiting for customer to redeem',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: reward.isVerified
                                                  ? MColors.primary
                                                  : MColors.primary
                                                      .withOpacity(0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
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
}

class RecentScansView extends StatelessWidget {
  final RestaurantController controller;

  const RecentScansView({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.recentScansStream(),
      builder: (context, snapshot) {
        // Super lightweight loading indicator
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading scans: ${snapshot.error}'),
          );
        }

        final scans = snapshot.data ?? [];

        // Empty state
        if (scans.isEmpty) {
          return Center(
            child: Text(
              'No scans yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        // Fast-loading list with minimal widgets
        return ListView.builder(
          itemCount: scans.length,
          itemBuilder: (context, index) {
            final scan = scans[index];
            final scanDate = scan['date'] as DateTime?;

            // Show date headers only for first item of each date
            String dateHeader = '';
            if (scanDate != null) {
              final currentDateStr = DateFormat('MMM d, yyyy').format(scanDate);
              if (index == 0) {
                dateHeader = currentDateStr;
              } else {
                final prevScan = scans[index - 1];
                final prevDate = prevScan['date'] as DateTime?;
                if (prevDate != null) {
                  final prevDateStr =
                      DateFormat('MMM d, yyyy').format(prevDate);
                  if (prevDateStr != currentDateStr) {
                    dateHeader = currentDateStr;
                  }
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header (only shown for first scan of each date)
                if (dateHeader.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text(
                      dateHeader,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Simplified scan item with fewer widgets
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: MColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person, color: MColors.primary),
                      ),
                      title: const Text('Customer'),
                      subtitle: Text(
                        scanDate != null
                            ? DateFormat('hh:mm a').format(scanDate)
                            : 'Unknown time',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      // trailing: Text(
                      //   '+${scan['points']} point',
                      //   style: const TextStyle(
                      //     color: MColors.primary,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
