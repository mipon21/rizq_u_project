import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/customer_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../widgets/customer/loading_shimmer.dart';

class RewardsTab extends StatefulWidget {
  final CustomerController controller;

  const RewardsTab({
    super.key,
    required this.controller,
  });

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  // Define reward icons map for consistency with program settings
  final Map<String, IconData> rewardIcons = {
    "Free Dessert": Icons.icecream,
    "Free Meal": Icons.restaurant,
    "Free Drink": Icons.local_bar,
    "Free Appetizer": Icons.fastfood,
    "default": Icons.card_giftcard,
  };

  @override
  bool get wantKeepAlive => true; // Keep the state when tab is not visible

  @override
  void initState() {
    super.initState();

    // Load cache immediately
    if (widget.controller.claimHistory.isEmpty &&
        !widget.controller.isLoadingHistory.value) {
      widget.controller.loadCachedClaimHistory();
    }

    // Setup scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        !widget.controller.isLoadingHistory.value &&
        widget.controller.hasMoreClaimHistory.value) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    setState(() {
      _isLoadingMore = true;
    });

    await widget.controller.loadMoreClaimHistory();

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshData() async {
    return widget.controller.refreshClaimHistory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      // Show skeleton loading if first load and no cached data
      if (widget.controller.isLoadingHistory.value &&
          widget.controller.claimHistory.isEmpty) {
        return LoadingShimmer.buildRewardHistoryShimmer();
      }

      if (widget.controller.claimHistory.isEmpty) {
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
        onRefresh: _refreshData,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: widget.controller.claimHistory.length +
              (_isLoadingMore || widget.controller.hasMoreClaimHistory.value
                  ? 1
                  : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom while pagination loads more items
            if (index >= widget.controller.claimHistory.length) {
              return LoadingShimmer.buildPaginationLoader();
            }

            final rewardItem = widget.controller.claimHistory[index];
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
                          backgroundColor: MColors.primary.withOpacity(0.8),
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
                                : MColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rewardItem.isVerified ? 'Claimed' : 'To Claim',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: rewardItem.isVerified
                                  ? Colors.green[800]
                                  : MColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            rewardIcons[rewardItem.rewardType] ??
                                rewardIcons["default"]!,
                            color: MColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rewardItem.rewardType,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: MColors.primary,
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
                                  border: Border.all(
                                      color: MColors.primary.withOpacity(0.5)),
                                ),
                                child: Text(
                                  rewardItem.id.substring(0, 6).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: MColors.primary,
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
