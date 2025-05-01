import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust import
import 'package:rizq/app/controllers/customer_controller.dart'; // Adjust import
import 'package:rizq/app/routes/app_pages.dart'; // Adjust import

class CustomerHomePage extends GetView<CustomerController> {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find(); // For logout

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
            child: Text(
              'Programmes de fidélité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingPrograms.value) {
                return const Center(child: CircularProgressIndicator());
              }
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
            label: 'Historique',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Get.toNamed(Routes.CUSTOMER_QR_CODE);
          } else if (index == 2) {
            Get.toNamed(Routes.CUSTOMER_SCAN_HISTORY);
          }
        },
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
