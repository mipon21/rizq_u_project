import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust import
import 'package:rizq/app/controllers/customer_controller.dart'; // Adjust import
import 'package:rizq/app/routes/app_pages.dart';
import 'package:rizq/app/utils/constants/colors.dart'; // Adjust import
import 'package:flutter/foundation.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> with RouteAware {
  final CustomerController controller = Get.find<CustomerController>();
  final AuthController authController = Get.find<AuthController>();
  final RouteObserver<PageRoute> routeObserver =
      Get.find<RouteObserver<PageRoute>>();

  @override
  void initState() {
    super.initState();
    // Fetch data when the page is created
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // Refresh data when returning to this page
    _refreshData();
  }

  @override
  void dispose() {
    // Unsubscribe from route observer
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Refresh data method
  void _refreshData() {
    controller.fetchAllRestaurantPrograms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 150,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'RIZQ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.indigo[700],
              ),
            ),
            Text(
              'رزق',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.indigo[700],
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            Get.toNamed(Routes.CUSTOMER_SCAN_HISTORY);
          },
          icon: const Icon(
            Icons.card_giftcard,
            color: MColors.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              authController.logout();
            },
            icon: const Icon(
              Icons.logout,
              color: MColors.primary,
            ),
          ),
        ],
      ),
      body: Column(
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
                  onPressed: _refreshData,
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
                    "UI Rebuild - isLoading: ${controller.isLoadingPrograms.value}, programs count: ${controller.allPrograms.length}");
              }

              if (controller.isLoadingPrograms.value) {
                return const Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Chargement des programmes...")
                  ],
                ));
              }

              // Handle the case where allPrograms is null or empty
              if (controller.allPrograms.isEmpty) {
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
                          onPressed: _refreshData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualiser'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.allPrograms.length,
                itemBuilder: (context, index) {
                  final program = controller.allPrograms[index];

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
                                backgroundImage: program.logoUrl.isNotEmpty
                                    ? NetworkImage(program.logoUrl)
                                    : null,
                                child: program.logoUrl.isEmpty
                                    ? Text(
                                        program.restaurantName.isNotEmpty
                                            ? program.restaurantName[0]
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
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
                              value: program.customerPoints /
                                  program.pointsRequired,
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
                                    _showClaimConfirmation(context, program),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'QR Code',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Get.toNamed(Routes.CUSTOMER_QR_CODE);
          } else if (index == 2) {
            Get.toNamed(Routes.CUSTOMER_PROFILE);
          }
        },
      ),
    );
  }

  // Show confirmation dialog before claiming a reward
  void _showClaimConfirmation(
      BuildContext context, RestaurantProgramModel program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réclamer ${program.rewardType}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir réclamer cette récompense chez ${program.restaurantName}?',
            ),
            const SizedBox(height: 12),
            const Text(
              'Vos points seront remis à zéro après réclamation.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.claimReward(program);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
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
}

// Separate widget for claim button to properly handle GetX reactivity
class ClaimButton extends StatefulWidget {
  final RestaurantProgramModel program;
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
              child: ElevatedButton(
                onPressed: isClaimingReward ? null : widget.onPressed,
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
                  children: [
                    if (isClaimingReward)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else ...[
                      const Icon(Icons.card_giftcard, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'RÉCLAMER MAINTENANT',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ]
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
