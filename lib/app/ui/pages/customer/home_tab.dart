import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/customer_controller.dart';
import '../../../utils/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/customer/loading_shimmer.dart';

class HomeTab extends StatefulWidget {
  final CustomerController controller;
  final Function() refreshData;
  final Function(dynamic) showClaimConfirmation;

  const HomeTab({
    super.key,
    required this.controller,
    required this.refreshData,
    required this.showClaimConfirmation,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load data when first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Try to load cached data first if available
      _loadInitialData();
    });
  }

  // Load cached data first and then refresh
  void _loadInitialData() async {
    // Check if we need to load cache first
    if (widget.controller.allPrograms.isEmpty &&
        !widget.controller.isLoadingPrograms.value) {
      await widget.controller.loadCachedRestaurantPrograms();
    }

    // Always refresh with network data
    widget.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loyalty programs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: widget.refreshData,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            // Add debug print to help identify issues
            if (kDebugMode) {
              print(
                  "UI Rebuild - isLoading: ${widget.controller.isLoadingPrograms.value}, programs count: ${widget.controller.allPrograms.length}");
            }

            // Initial loading with empty data
            if (widget.controller.isLoadingPrograms.value &&
                widget.controller.allPrograms.isEmpty) {
              return LoadingShimmer.buildCardShimmer();
            }

            // Handle the case where allPrograms is null or empty
            if (widget.controller.allPrograms.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No loyalty program available',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan the QR code to see the loyalty programs',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: widget.refreshData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Refreshing with existing data? Show shimmer cards instead of overlay
            if (widget.controller.isLoadingPrograms.value) {
              return LoadingShimmer.buildCardShimmer();
            }

            // Show normal content when not loading
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.controller.allPrograms.length,
              itemBuilder: (context, index) {
                final program = widget.controller.allPrograms[index];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                   decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Restaurant logo or placeholder
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _getAvatarColor(index),
                              child: program.logoUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: CachedNetworkImage(
                                        imageUrl: program.logoUrl,
                                        fit: BoxFit.cover,
                                        width: 32,
                                        height: 32,
                                        placeholder: (context, url) =>
                                            Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.grey.shade300,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Text(
                                          program.restaurantName.isNotEmpty
                                              ? program.restaurantName[0]
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      program.restaurantName.isNotEmpty
                                          ? program.restaurantName[0]
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    program.restaurantName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${program.customerPoints}/${program.pointsRequired} points',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            program.rewardReady
                                ? SizedBox(
                                    width: 80,
                                    child: ClaimButton(
                                      program: program,
                                      onPressed: () =>
                                          widget.showClaimConfirmation(program),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'In progress',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value:
                                program.customerPoints / program.pointsRequired,
                            minHeight: 4,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(index, program.rewardReady),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Reward text
                        Text(
                          program.rewardType,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                _getProgressColor(index, program.rewardReady),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // Helper methods to get consistent colors for restaurants
  Color _getAvatarColor(int index) {
    final colors = [
      Colors.orange,
      Colors.purple[800],
      Colors.red[400],
    ];
    return colors[index % colors.length]!;
  }

  // Color _getProgressColor(int index, bool isReady) {
  //   if (isReady) return Colors.purple;

  //   final colors = [
  //     Colors.orange,
  //     Colors.purple[800],
  //     Colors.red[400],
  //   ];
  //   return colors[index % colors.length]!;
  // }

  Color _getProgressColor(int index, bool isReady) {
    return Theme.of(context).colorScheme.primary;
  }


}

// Separate widget for claim button to properly handle GetX reactivity
class ClaimButton extends StatefulWidget {
  final dynamic program;
  final VoidCallback onPressed;

  const ClaimButton({
    super.key,
    required this.program,
    required this.onPressed,
  });

  @override
  State<ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<ClaimButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final CustomerController controller = Get.find();

  @override
  void initState() {
    super.initState();
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isClaimingReward = controller.isClaimingReward.value;

      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isClaimingReward ? 1.0 : _scaleAnimation.value,
            child: SizedBox(
              width: double.infinity,
              child: isClaimingReward
                  ? Container(
                      width: double.infinity,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: widget.onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(0, 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 1,
                      ),
                      child: const Text(
                        'CLAIM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          );
        },
      );
    });
  }
}
