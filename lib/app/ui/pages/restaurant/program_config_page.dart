import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:get/get.dart';
import 'package:rizq/app/controllers/program_controller.dart'; // Adjust import

class ProgramConfigPage extends StatefulWidget {
  const ProgramConfigPage({Key? key}) : super(key: key);

  @override
  State<ProgramConfigPage> createState() => _ProgramConfigPageState();
}

class _ProgramConfigPageState extends State<ProgramConfigPage> {
  final ProgramController controller = Get.find();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController rewardTypeController;

  // Example reward types - could fetch from backend or be static
  final List<String> rewardOptions = [
    "Free Coffee",
    "Free Meal",
    "10% Discount",
    "Free Appetizer",
  ];
  late RxString selectedRewardType; // Use RxString if using Dropdown

  @override
  void initState() {
    super.initState();
    rewardTypeController = TextEditingController(
      text: controller.currentRewardType,
    );
    selectedRewardType =
        controller.currentRewardType.obs; // Initialize RxString

    // Update local fields if controller data loads later
    ever(controller.loyaltyProgram, (_) {
      if (mounted && controller.loyaltyProgram.value != null) {
        rewardTypeController.text = controller.currentRewardType;
        selectedRewardType.value = controller.currentRewardType;
      }
    });
  }

  @override
  void dispose() {
    rewardTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Program Settings')),
      body: Obx(() {
        if (controller.isLoading.value) {
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
                const SizedBox(height: 30),

                // --- Option 1: Dropdown for reward type ---
                const Text(
                  'Select Reward Type:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                // Replace dropdown with card selection
                Obx(() => GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: rewardOptions.map((rewardType) {
                        final isSelected =
                            selectedRewardType.value == rewardType;
                        return GestureDetector(
                          onTap: () {
                            selectedRewardType.value = rewardType;
                            rewardTypeController.text = rewardType;
                          },
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
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  rewardType,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 15),
                const Text(
                  'Or enter a custom reward type below:',
                  style: TextStyle(color: Colors.grey),
                ),
                // --- Option 2: TextField for reward type ---
                TextFormField(
                  controller: rewardTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Reward Description (e.g., Free Coffee)',
                    hintText: 'Enter custom reward...',
                  ),
                  onChanged: (value) => selectedRewardType.value =
                      value, // Update dropdown selection if typing
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reward description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Replace editable Points Required field with fixed display
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stars,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Points Required for Reward',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '10',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'points',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: 'Points required is fixed at 10',
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Save Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        // Use fixed value 10 for points
                        controller.updateLoyaltyProgram(
                          rewardTypeController.text.trim(),
                          10, // Fixed at 10 points
                        );
                        Get.back(); // Go back after saving
                      }
                    },
                    child: const Text('Save Program Settings'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
