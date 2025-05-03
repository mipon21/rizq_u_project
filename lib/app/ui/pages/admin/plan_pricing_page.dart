import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/admin_controller.dart';

class PlanPricingPage extends GetView<AdminController> {
  const PlanPricingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Pricing Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => controller.isPricingLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Scan Package Prices',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  _buildPlanPriceCard(
                    context,
                    'Basic Plan (100 Scans)',
                    'plan_100',
                    controller.planPrices['plan_100'] ?? 99.99,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanPriceCard(
                    context,
                    'Standard Plan (250 Scans)',
                    'plan_250',
                    controller.planPrices['plan_250'] ?? 199.99,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanPriceCard(
                    context,
                    'Premium Plan (Unlimited Scans)',
                    'plan_unlimited',
                    controller.planPrices['plan_unlimited'] ?? 299.99,
                  ),
                ],
              )),
      ),
    );
  }

  Widget _buildPlanPriceCard(BuildContext context, String title,
      String planCode, double currentPrice) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Text(
                    'Current Price: €${currentPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        _showPriceEditDialog(context, planCode, currentPrice),
                    child: const Text('Change Price'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceEditDialog(
      BuildContext context, String planCode, double currentPrice) {
    final priceController =
        TextEditingController(text: currentPrice.toString());

    Get.dialog(
      AlertDialog(
        title: Text('Edit ${_formatPlanName(planCode)} Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price (€)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newPrice = double.tryParse(priceController.text.trim());
                if (newPrice == null || newPrice <= 0) {
                  Get.snackbar(
                    'Error',
                    'Please enter a valid price greater than zero',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                await controller.updatePlanPrice(planCode, newPrice);
                Get.back();
                Get.snackbar(
                  'Success',
                  'Price updated successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to update price: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatPlanName(String planCode) {
    switch (planCode) {
      case 'plan_100':
        return 'Basic (100 Scans)';
      case 'plan_250':
        return 'Standard (250 Scans)';
      case 'plan_unlimited':
        return 'Premium (Unlimited)';
      default:
        return planCode;
    }
  }
}
