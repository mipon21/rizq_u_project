import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/customer_controller.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeTab extends StatefulWidget {
  final CustomerController controller;
  final Function() refreshData;
  final Function(dynamic) showClaimConfirmation;

  const HomeTab({
    Key? key,
    required this.controller,
    required this.refreshData,
    required this.showClaimConfirmation,
  }) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      widget.refreshData();
    }
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
                'Programmes de fidélité',
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
              return _buildLoadingShimmer();
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
                        'Aucun programme de fidélité disponible',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Revenez plus tard pour voir les programmes disponibles',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: widget.refreshData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Refreshing with existing data? Show shimmer cards instead of overlay
            if (widget.controller.isLoadingPrograms.value) {
              return _buildLoadingShimmer();
            }

            // Show normal content when not loading
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.controller.allPrograms.length,
              itemBuilder: (context, index) {
                final program = widget.controller.allPrograms[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Restaurant logo or placeholder
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: _getAvatarColor(index),
                              child: program.logoUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: CachedNetworkImage(
                                        imageUrl: program.logoUrl,
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                        placeholder: (context, url) =>
                                            Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Shimmer.fromColors(
                                            baseColor:
                                                Colors.white.withOpacity(0.5),
                                            highlightColor: Colors.white,
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
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

                            // Restaurant name and points
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    program.restaurantName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${program.customerPoints} / ${program.pointsRequired}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: program.rewardReady
                                    ? Colors.purple[100]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                program.rewardReady
                                    ? 'Récompense\nobtenue'
                                    : 'En cours',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: program.rewardReady
                                      ? Colors.purple[900]
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value:
                                program.customerPoints / program.pointsRequired,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(index, program.rewardReady),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

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

                        // Claim button (only if reward is ready)
                        if (program.rewardReady)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ClaimButton(
                              program: program,
                              onPressed: () =>
                                  widget.showClaimConfirmation(program),
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

  Color _getProgressColor(int index, bool isReady) {
    if (isReady) return Colors.purple;

    final colors = [
      Colors.orange,
      Colors.purple[800],
      Colors.red[400],
    ];
    return colors[index % colors.length]!;
  }

  // Update the _buildLoadingShimmer method with a more realistic card loading effect
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Shimmer for restaurant logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shimmer for restaurant name and points
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Shimmer for status tag
                    Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Shimmer for progress bar
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                // Shimmer for reward description
                Container(
                  width: 150,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                // Shimmer for claim button
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
        ),
      ),
    );
  }
}

// Separate widget for claim button to properly handle GetX reactivity
class ClaimButton extends StatefulWidget {
  final dynamic program;
  final VoidCallback onPressed;

  const ClaimButton({
    Key? key,
    required this.program,
    required this.onPressed,
  }) : super(key: key);

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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: widget.onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.card_giftcard, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'RÉCLAMER MAINTENANT',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      );
    });
  }
}
