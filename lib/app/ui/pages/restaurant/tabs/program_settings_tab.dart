import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:rizq/app/controllers/program_controller.dart';
import 'package:intl/intl.dart';

class ProgramSettingsTab extends StatelessWidget {
  const ProgramSettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProgramController programController = Get.find<ProgramController>();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final List<String> rewardOptions = [
      "Free Dessert",
      "Free Meal",
      "Free Drink",
      "Free Appetizer",
    ];
    final TextEditingController rewardTypeController = TextEditingController(
      text: programController.currentRewardType,
    );
    final RxString selectedRewardType = programController.currentRewardType.obs;

    // Define reward icons map for consistency
    final Map<String, IconData> rewardIcons = {
      "Free Dessert": Icons.icecream,
      "Free Meal": Icons.restaurant,
      "Free Drink": Icons.local_bar,
      "Free Appetizer": Icons.fastfood,
      "default": Icons.card_giftcard,
    };

    ever(programController.loyaltyProgram, (_) {
      if (programController.loyaltyProgram.value != null) {
        rewardTypeController.text = programController.currentRewardType;
        selectedRewardType.value = programController.currentRewardType;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        if (programController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure Your Reward',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4),
                        spreadRadius: 1,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('1 Scan = 1 Point',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      Text('10 Points = 1 Reward',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Select Reward Type:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  // Calculate card width - 2 cards in a row with 10dp spacing between
                  final availableWidth = MediaQuery.of(context).size.width -
                      50; // Accounting for padding and spacing
                  final cardWidth = (availableWidth - 10) /
                      2; // Two cards per row with 10dp spacing

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First row with 2 items
                      Row(
                        children: [
                          _buildRewardCard(
                              context,
                              rewardOptions[0],
                              selectedRewardType.value,
                              rewardIcons[rewardOptions[0]] ??
                                  rewardIcons["default"]!, () {
                            selectedRewardType.value = rewardOptions[0];
                            rewardTypeController.text = rewardOptions[0];
                          }),
                          const SizedBox(width: 10),
                          _buildRewardCard(
                              context,
                              rewardOptions[1],
                              selectedRewardType.value,
                              rewardIcons[rewardOptions[1]] ??
                                  rewardIcons["default"]!, () {
                            selectedRewardType.value = rewardOptions[1];
                            rewardTypeController.text = rewardOptions[1];
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Second row with 2 items
                      Row(
                        children: [
                          _buildRewardCard(
                              context,
                              rewardOptions[2],
                              selectedRewardType.value,
                              rewardIcons[rewardOptions[2]] ??
                                  rewardIcons["default"]!, () {
                            selectedRewardType.value = rewardOptions[2];
                            rewardTypeController.text = rewardOptions[2];
                          }),
                          const SizedBox(width: 10),
                          _buildRewardCard(
                              context,
                              rewardOptions[3],
                              selectedRewardType.value,
                              rewardIcons[rewardOptions[3]] ??
                                  rewardIcons["default"]!, () {
                            selectedRewardType.value = rewardOptions[3];
                            rewardTypeController.text = rewardOptions[3];
                          }),
                        ],
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 15),
                // Highlighted custom reward text
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Custom reward option has been taken to consideration',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stars,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Points Required for Reward:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '10',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'points',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(fixed)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    label: const Text('Save program settings'),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        programController.updateLoyaltyProgram(
                          rewardTypeController.text.trim(),
                          10, // Fixed at 10 points
                        );
                        Get.snackbar('Success', 'Program settings updated!');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// Helper method to build reward card
Widget _buildRewardCard(BuildContext context, String rewardType,
    String selectedType, IconData iconData, VoidCallback onTap) {
  final isSelected = selectedType == rewardType;

  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: SizedBox(
          height: 60, // Slightly reduced height
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(
                  iconData,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: Text(
                      rewardType,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// Same card but without Expanded widget for the centered card
Widget _buildSingleRewardCard(BuildContext context, String rewardType,
    String selectedType, IconData iconData, VoidCallback onTap) {
  final isSelected = selectedType == rewardType;

  return GestureDetector(
    onTap: onTap,
    child: Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: SizedBox(
        height: 90, // Same slightly reduced height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                rewardType,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
