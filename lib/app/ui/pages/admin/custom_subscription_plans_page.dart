import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/subscription_plan_model.dart';
import '../../../utils/constants/colors.dart';

class CustomSubscriptionPlansPage extends GetView<AdminController> {
  const CustomSubscriptionPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Subscription Plans'),
        backgroundColor: MColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Plan',
            onPressed: () => _showCreatePlanDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingSubscriptionPlans.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.subscriptionPlans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.subscriptions_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No subscription plans created yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first subscription plan to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create First Plan'),
                  onPressed: () => _showCreatePlanDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.subscriptionPlans.length,
          itemBuilder: (context, index) {
            final plan = controller.subscriptionPlans[index];
            return _buildPlanCard(context, plan);
          },
        );
      }),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlanModel plan) {
    // Remove special styling for free trial plan
    final cardColor = null;
    final borderColor = plan.isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                plan.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (plan.isInitial)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Initial Plan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (plan.isFreeTrial)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Free Trial',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (!plan.isFreeTrial)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: plan.isActive ? Colors.green : Colors.grey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    plan.isActive ? 'Active' : 'Inactive',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.formattedPrice,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: MColors.primary,
                          ),
                        ),
                        Text(
                          'for ${plan.formattedDuration}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildInfoChip(
                  icon: Icons.qr_code_scanner,
                  label: plan.formattedScanLimit,
                  color: Colors.blue,
                ),
                _buildInfoChip(
                  icon: Icons.calendar_today,
                  label: plan.formattedDuration,
                  color: Colors.orange,
                ),
              ],
            ),
            if (plan.features.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...plan.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: (16).isFinite && 16 > 0 ? 16 : 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created: ${_formatDate(plan.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Show toggle for all plans, including free trial
                    Switch(
                      value: plan.isActive,
                      onChanged: (value) =>
                          controller.toggleSubscriptionPlanStatus(
                        plan.id,
                        value,
                      ),
                      activeColor: Colors.green,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditPlanDialog(context, plan),
                      tooltip: 'Edit Plan',
                    ),
                    if (!plan.isFreeTrial)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, plan),
                        tooltip: 'Delete Plan',
                      ),
                    if (!plan.isInitial && plan.isActive)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.star_border, size: 18),
                        label: const Text('Set as Initial'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          side: const BorderSide(color: Colors.deepPurple),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        onPressed: () => controller.setInitialSubscriptionPlan(plan.id),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: (16).isFinite && 16 > 0 ? 16 : 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlanDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final scanLimitController = TextEditingController();
    final durationController = TextEditingController();
    final priceController = TextEditingController();
    final featuresController = TextEditingController();
    final planTypeController = TextEditingController(text: 'regular');

    Get.dialog(
      AlertDialog(
        title: const Text('Create New Subscription Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: scanLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Scan Limit',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (days)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 30',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (MAD)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 100',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: featuresController,
                decoration: const InputDecoration(
                  labelText: 'Features (comma-separated)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Basic analytics, Email support',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Plan Type',
                  border: OutlineInputBorder(),
                ),
                value: planTypeController.text,
                items: const [
                  DropdownMenuItem(value: 'regular', child: Text('Regular Plan')),
                  DropdownMenuItem(value: 'free_trial', child: Text('Free Trial Plan')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    planTypeController.text = value;
                    // Auto-fill price for free trial
                    if (value == 'free_trial') {
                      priceController.text = '0';
                    }
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_validatePlanForm(
                nameController,
                descriptionController,
                scanLimitController,
                durationController,
                priceController,
                planTypeController, // pass planTypeController for create dialog
              )) {
                final features = featuresController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                controller.createSubscriptionPlan(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  scanLimit: int.parse(scanLimitController.text.trim()),
                  durationDays: int.parse(durationController.text.trim()),
                  price: double.parse(priceController.text.trim()),
                  features: features,
                  planType: planTypeController.text,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Plan'),
          ),
        ],
      ),
    );
  }

  void _showEditPlanDialog(BuildContext context, SubscriptionPlanModel plan) {
    final nameController = TextEditingController(text: plan.name);
    final descriptionController = TextEditingController(text: plan.description);
    final scanLimitController =
        TextEditingController(text: plan.scanLimit.toString());
    final durationController =
        TextEditingController(text: plan.durationDays.toString());
    final priceController = TextEditingController(text: plan.price.toString());
    final featuresController =
        TextEditingController(text: plan.features.join(', '));
    bool isActive = plan.isActive;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Subscription Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: scanLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Scan Limit',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (days)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 30',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (MAD)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 100',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: featuresController,
                decoration: const InputDecoration(
                  labelText: 'Features (comma-separated)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Basic analytics, Email support',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (plan.isFreeTrial)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is a Free Trial plan. It will be automatically assigned to new restaurants upon approval.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!plan.isFreeTrial) ...[
                Row(
                  children: [
                    const Text('Active: '),
                    Switch(
                      value: isActive,
                      onChanged: (value) => isActive = value,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_validatePlanForm(
                nameController,
                descriptionController,
                scanLimitController,
                durationController,
                priceController,
                null, // pass null for edit dialog
              )) {
                final features = featuresController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                controller.updateSubscriptionPlan(
                  planId: plan.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  scanLimit: int.parse(scanLimitController.text.trim()),
                  durationDays: int.parse(durationController.text.trim()),
                  price: double.parse(priceController.text.trim()),
                  isActive: isActive,
                  features: features,
                  planType: plan.planType,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Plan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, SubscriptionPlanModel plan) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Subscription Plan'),
        content: Text(
          'Are you sure you want to delete "${plan.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSubscriptionPlan(plan.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  bool _validatePlanForm(
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController scanLimitController,
    TextEditingController durationController,
    TextEditingController priceController,
    [TextEditingController? planTypeController] // optional, for new dialog
  ) {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Plan name is required');
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Description is required');
      return false;
    }
    if (scanLimitController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Scan limit is required');
      return false;
    }
    if (durationController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Duration is required');
      return false;
    }
    if (priceController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Price is required');
      return false;
    }

    final scanLimit = int.tryParse(scanLimitController.text.trim());
    final duration = int.tryParse(durationController.text.trim());
    final price = double.tryParse(priceController.text.trim());

    if (scanLimit == null || scanLimit <= 0) {
      Get.snackbar('Error', 'Scan limit must be a positive number');
      return false;
    }
    if (duration == null || duration <= 0) {
      Get.snackbar('Error', 'Duration must be a positive number');
      return false;
    }

    // Allow price = 0 for free_trial plans
    String planType = planTypeController?.text ?? '';
    if (planType.isEmpty && nameController.text.toLowerCase().contains('free trial')) {
      planType = 'free_trial';
    }
    if (price == null || price < 0 || (planType != 'free_trial' && price == 0)) {
      Get.snackbar('Error', 'Price must be a positive number');
      return false;
    }

    return true;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
