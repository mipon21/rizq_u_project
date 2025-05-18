import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/customer_controller.dart';
import 'package:rizq/app/utils/constants/colors.dart'; // Adjust import
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ScanHistoryPage extends StatefulWidget {
  const ScanHistoryPage({Key? key}) : super(key: key);

  @override
  State<ScanHistoryPage> createState() => _ScanHistoryPageState();
}

class _ScanHistoryPageState extends State<ScanHistoryPage>
    with WidgetsBindingObserver {
  final CustomerController controller = Get.find();
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();

    // Refresh data immediately when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes to foreground
      _refreshData();
    }
  }

  void _refreshData() {
    controller.refreshClaimHistory();
    controller.fetchScanHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _refreshData();
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Image.asset('assets/icons/general-u.png', height: 70),
            toolbarHeight: 80,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: MColors.primary,
              ),
              onPressed: () => Get.back(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: Colors.white, // Set your desired background color here
                child: TabBar(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicator: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  indicatorColor: Colors.transparent,
                  indicatorWeight: 0,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.qr_code_scanner),
                      child: Text('Claim Rewards'),
                    ),
                    Tab(
                      icon: Icon(Icons.card_giftcard),
                      child: Text('Points History'),
                    ),
                  ],
                ),
              ),
            ),
            shadowColor: Colors.transparent,
          ),
          body: TabBarView(
            children: [
              _buildRewardHistoryTab(),
              _buildScanHistoryTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanHistoryTab() {
    return Obx(() {
      if (controller.isLoadingHistory.value) {
        return _buildShimmerList();
      }
      if (controller.scanHistory.isEmpty) {
        return const Center(child: Text('No scans recorded yet.'));
      }
      return RefreshIndicator(
        onRefresh: () => controller.fetchScanHistory(),
        child: ListView.builder(
          itemCount: controller.scanHistory.length,
          itemBuilder: (context, index) {
            final historyItem = controller.scanHistory[index];
            return ListTile(
              leading: const Icon(Icons.qr_code_scanner_outlined),
              title: Text(historyItem.restaurantName),
              subtitle: Text(
                historyItem.formattedTimestamp,
              ), // Use formatted date
              trailing: Text(
                '+${historyItem.pointsAwarded} pt${historyItem.pointsAwarded > 1 ? 's' : ''}',
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildRewardHistoryTab() {
    return Obx(() {
      if (controller.isLoadingHistory.value) {
        return _buildShimmerCards();
      }
      if (controller.claimHistory.isEmpty) {
        return Center(
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
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => controller.refreshClaimHistory(),
        child: ListView.builder(
          itemCount: controller.claimHistory.length,
          itemBuilder: (context, index) {
            final rewardItem = controller.claimHistory[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple[700],
                          child: Icon(
                            rewardItem.isVerified
                                ? Icons.verified
                                : Icons.redeem,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rewardItem.restaurantName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                rewardItem.formattedClaimDate,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rewardItem.isVerified
                                ? Colors.green[100]
                                : Colors.purple[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rewardItem.isVerified ? 'REDEEMED' : 'CLAIMED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: rewardItem.isVerified
                                  ? Colors.green[800]
                                  : Colors.purple[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            color: Colors.purple[800],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rewardItem.rewardType,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.purple[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add verification code section
                    if (!rewardItem.isVerified)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Show this code to the restaurant to redeem:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.purple[300]!),
                                ),
                                child: Text(
                                  rewardItem.id.substring(0, 6).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Colors.purple[800],
                                  ),
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
      );
    });
  }

  // Add shimmer effect for list items
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            title: Container(
              width: double.infinity,
              height: 16,
              color: Colors.white,
            ),
            subtitle: Container(
              width: 150,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
              color: Colors.white,
            ),
            trailing: Container(
              width: 40,
              height: 16,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  // Add shimmer effect for card items
  Widget _buildShimmerCards() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 80,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: double.infinity,
                    height: 1,
                    color: Colors.white,
                  ),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
