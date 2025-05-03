import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/customer_controller.dart';
import 'package:rizq/app/utils/constants/colors.dart'; // Adjust import

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
    controller.fetchClaimHistory();
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
            title: const Text('My History'),
            bottom: const TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: MColors.white,
              indicator: BoxDecoration(
                color: Color.fromARGB(255, 114, 88, 201),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: MColors.white,
                  ),
                  child: Text(
                    'Claim Rewards',
                    style: TextStyle(color: MColors.white),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.card_giftcard, color: MColors.white),
                  child: Text(
                    'Points History',
                    style: TextStyle(color: MColors.white),
                  ),
                ),
              ],
            ),
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
        return const Center(child: CircularProgressIndicator());
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
        return const Center(child: CircularProgressIndicator());
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
        onRefresh: () => controller.fetchClaimHistory(),
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
}
