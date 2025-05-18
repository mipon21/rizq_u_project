import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../utils/constants/colors.dart';

class PlanPricingPage extends GetView<AdminController> {
  const PlanPricingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plan Pricing'),
        backgroundColor: MColors.primary,
      ),
      body: Obx(() {
        if (controller.isPricingLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage Subscription Plans',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set pricing for different subscription tiers. Changes will affect new subscriptions only.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              _buildPlanCard(
                title: 'Basic Plan',
                subtitle: 'Up to 100 customers',
                planKey: 'plan_100',
                features: [
                  'Track up to 100 unique customers',
                  'Basic loyalty program',
                  'Email support',
                  'Standard analytics',
                ],
                color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
              _buildPlanCard(
                title: 'Standard Plan',
                subtitle: 'Up to 250 customers',
                planKey: 'plan_250',
                features: [
                  'Track up to 250 unique customers',
                  'Advanced loyalty program',
                  'Priority email support',
                  'Enhanced analytics',
                  'Custom branding',
                ],
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildPlanCard(
                title: 'Premium Plan',
                subtitle: 'Unlimited customers',
                planKey: 'plan_unlimited',
                features: [
                  'Track unlimited customers',
                  'Advanced loyalty program',
                  'Priority phone & email support',
                  'Advanced analytics & reporting',
                  'Custom branding',
                  'API access',
                  'Dedicated account manager',
                ],
                color: Colors.purple,
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  onPressed: _savePriceChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required String planKey,
    required List<String> features,
    required Color color,
  }) {
    final priceController = TextEditingController(
      text: controller.planPrices[planKey]?.toString() ?? '0.00',
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '\$',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: TextFormField(
              controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
              decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              try {
                                final newPrice = double.parse(value);
                                controller.planPrices[planKey] = newPrice;
                              } catch (e) {
                                // Ignore invalid input
                              }
                            }
                          },
                        ),
                      ),
                      const Text(
                        '/month',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Features:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _savePriceChanges() {
    // Validate prices
    if (controller.planPrices['plan_100'] == null ||
        controller.planPrices['plan_250'] == null ||
        controller.planPrices['plan_unlimited'] == null) {
                  Get.snackbar(
                    'Error',
        'All plan prices must be set',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

    if (controller.planPrices['plan_100']! <= 0 ||
        controller.planPrices['plan_250']! <= 0 ||
        controller.planPrices['plan_unlimited']! <= 0) {
                Get.snackbar(
        'Error',
        'Plan prices must be greater than zero',
                  snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
      return;
    }

    // Ensure pricing tiers make sense
    if (controller.planPrices['plan_100']! >=
        controller.planPrices['plan_250']!) {
                Get.snackbar(
                  'Error',
        'Basic plan price should be less than Standard plan price',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
      return;
    }

    if (controller.planPrices['plan_250']! >=
        controller.planPrices['plan_unlimited']!) {
      Get.snackbar(
        'Error',
        'Standard plan price should be less than Premium plan price',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Save changes
    controller.updatePlanPrices(controller.planPrices);
  }
}
