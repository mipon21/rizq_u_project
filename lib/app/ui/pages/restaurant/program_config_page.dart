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
  late TextEditingController pointsRequiredController;

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
    pointsRequiredController = TextEditingController(
      text: controller.currentPointsRequired.toString(),
    );
    selectedRewardType =
        controller.currentRewardType.obs; // Initialize RxString

    // Update local fields if controller data loads later
    ever(controller.loyaltyProgram, (_) {
      if (mounted && controller.loyaltyProgram.value != null) {
        rewardTypeController.text = controller.currentRewardType;
        pointsRequiredController.text =
            controller.currentPointsRequired.toString();
        selectedRewardType.value = controller.currentRewardType;
      }
    });
  }

  @override
  void dispose() {
    rewardTypeController.dispose();
    pointsRequiredController.dispose();
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
                DropdownButtonFormField<String>(
                  value:
                      rewardOptions.contains(selectedRewardType.value)
                          ? selectedRewardType.value
                          : null, // Handle initial state if not in options
                  items:
                      rewardOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      selectedRewardType.value = newValue;
                      rewardTypeController.text =
                          newValue; // Keep text controller in sync
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                  ),
                  validator:
                      (value) =>
                          value == null ? 'Please select a reward type' : null,
                ),
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
                  onChanged:
                      (value) =>
                          selectedRewardType.value =
                              value, // Update dropdown selection if typing
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reward description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Points Required Field
                TextFormField(
                  controller: pointsRequiredController,
                  decoration: const InputDecoration(
                    labelText: 'Points Required for Reward',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter points required';
                    }
                    final points = int.tryParse(value);
                    if (points == null || points <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Save Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final points = int.parse(pointsRequiredController.text);
                        controller.updateLoyaltyProgram(
                          rewardTypeController.text
                              .trim(), // Use text field value
                          points,
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
