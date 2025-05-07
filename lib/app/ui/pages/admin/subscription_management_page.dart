import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import '../../../routes/app_pages.dart';

class SubscriptionManagementPage extends GetView<AdminController> {
  const SubscriptionManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        backgroundColor: MColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: 'Manage Scan Pricing',
            onPressed: () => Get.toNamed(Routes.ADMIN_PLAN_PRICING),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Subscriptions',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('restaurants')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No subscription data found'));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Desktop/tablet view with data table
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Restaurant')),
                              DataColumn(label: Text('Plan')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Start Date')),
                              DataColumn(label: Text('End Date')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Unknown';
                              final subscriptionPlan =
                                  data['subscriptionPlan'] ?? 'No plan';
                              final subscriptionStatus =
                                  data['subscriptionStatus'] ?? 'inactive';

                              final startDate =
                                  data['subscriptionStart'] != null
                                      ? (data['subscriptionStart'] as Timestamp)
                                          .toDate()
                                      : null;

                              final endDate = data['subscriptionEnd'] != null
                                  ? (data['subscriptionEnd'] as Timestamp)
                                      .toDate()
                                  : null;

                              final paymentStatus =
                                  data['paymentStatus'] ?? 'unpaid';

                              return DataRow(
                                cells: [
                                  DataCell(Text(name)),
                                  DataCell(
                                      Text(_formatPlanName(subscriptionPlan))),
                                  DataCell(
                                    Chip(
                                      label: Text(
                                        subscriptionStatus,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor:
                                          _getStatusColor(subscriptionStatus),
                                    ),
                                  ),
                                  DataCell(Text(startDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(startDate)
                                      : 'N/A')),
                                  DataCell(Text(endDate != null
                                      ? DateFormat('dd/MM/yyyy').format(endDate)
                                      : 'N/A')),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: () => _showRenewDialog(
                                            context, doc.id, data),
                                        child: const Text('Renew'),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          paymentStatus == 'paid'
                                              ? Icons.check_circle
                                              : Icons.money_off,
                                          color: paymentStatus == 'paid'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        onPressed: () => _togglePaymentStatus(
                                            doc.id, paymentStatus),
                                        tooltip: paymentStatus == 'paid'
                                            ? 'Mark as Unpaid'
                                            : 'Mark as Paid',
                                      ),
                                    ],
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    } else {
                      // Mobile view with list tiles
                      return ListView.separated(
                        itemCount: snapshot.data!.docs.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unknown';
                          final subscriptionPlan =
                              data['subscriptionPlan'] ?? 'No plan';
                          final subscriptionStatus =
                              data['subscriptionStatus'] ?? 'inactive';
                          final paymentStatus =
                              data['paymentStatus'] ?? 'unpaid';

                          final endDate = data['subscriptionEnd'] != null
                              ? (data['subscriptionEnd'] as Timestamp).toDate()
                              : null;

                          return ListTile(
                            title: Text(name),
                            subtitle: Text(
                                '${_formatPlanName(subscriptionPlan)} - ${endDate != null ? "Expires: ${DateFormat('dd/MM/yyyy').format(endDate)}" : "No end date"}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    subscriptionStatus,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor:
                                      _getStatusColor(subscriptionStatus),
                                ),
                                IconButton(
                                  icon: Icon(
                                    paymentStatus == 'paid'
                                        ? Icons.check_circle
                                        : Icons.money_off,
                                    color: paymentStatus == 'paid'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  onPressed: () => _togglePaymentStatus(
                                      doc.id, paymentStatus),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showSubscriptionDetails(context, doc.id, data),
                          );
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSubscriptionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Subscription'),
      ),
    );
  }

  String _formatPlanName(String planCode) {
    switch (planCode) {
      case 'free_trial':
        return 'Free Trial';
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'free_trial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _togglePaymentStatus(
      String restaurantId, String currentStatus) async {
    final newStatus = currentStatus == 'paid' ? 'unpaid' : 'paid';

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .update({
        'paymentStatus': newStatus,
      });

      // If marking as paid and subscription is inactive, make it active
      if (newStatus == 'paid') {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .get();
        final data = docSnapshot.data();

        if (data != null && data['subscriptionStatus'] == 'inactive') {
          // Calculate new end date (e.g., 30 days from now)
          final now = DateTime.now();
          final endDate = now.add(const Duration(days: 30));

          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(restaurantId)
              .update({
            'subscriptionStatus': 'active',
            'subscriptionStart': Timestamp.fromDate(now),
            'subscriptionEnd': Timestamp.fromDate(endDate),
          });
        }
      }

      Get.snackbar(
        'Success',
        'Payment status updated to ${newStatus.toUpperCase()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update payment status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showRenewDialog(
      BuildContext context, String restaurantId, Map<String, dynamic> data) {
    final durationController = TextEditingController(text: '30');
    String selectedPlan = data['subscriptionPlan'] ?? 'plan_100';

    Get.dialog(
      AlertDialog(
        title: const Text('Renew Subscription'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Restaurant: ${data['name'] ?? 'Unknown'}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPlan,
                decoration: const InputDecoration(
                  labelText: 'Subscription Plan',
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'plan_100', child: Text('Basic (100 Scans)')),
                  DropdownMenuItem(
                      value: 'plan_250', child: Text('Standard (250 Scans)')),
                  DropdownMenuItem(
                      value: 'plan_unlimited',
                      child: Text('Premium (Unlimited)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedPlan = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (days)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  // Parse duration
                  final duration =
                      int.tryParse(durationController.text.trim()) ?? 30;

                  // Calculate start and end dates
                  final now = DateTime.now();
                  final endDate = now.add(Duration(days: duration));

                  // Update subscription in Firestore
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .update({
                    'subscriptionPlan': selectedPlan,
                    'subscriptionStatus': 'active',
                    'subscriptionStart': Timestamp.fromDate(now),
                    'subscriptionEnd': Timestamp.fromDate(endDate),
                    'paymentStatus': 'paid', // Assume payment is made
                  });

                  // Record subscription transaction
                  await FirebaseFirestore.instance
                      .collection('subscriptions')
                      .add({
                    'restaurantId': restaurantId,
                    'plan': selectedPlan,
                    'startDate': Timestamp.fromDate(now),
                    'endDate': Timestamp.fromDate(endDate),
                    'amountPaid': _getPlanAmount(selectedPlan),
                    'duration': duration,
                    'timestamp': Timestamp.fromDate(now),
                  });

                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Subscription renewed successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to renew subscription: $e',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Renew'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSubscriptionDialog(BuildContext context) {
    String selectedRestaurantId = '';
    String selectedPlan = 'plan_100';
    final durationController = TextEditingController(text: '30');

    Get.dialog(
      AlertDialog(
        title: const Text('Create Subscription'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('restaurants')
                    .where('subscriptionStatus', isEqualTo: 'inactive')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No inactive restaurants found');
                  }

                  final restaurants = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    hint: const Text('Select Restaurant'),
                    decoration: const InputDecoration(
                      labelText: 'Restaurant',
                    ),
                    items: restaurants.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedRestaurantId = value;
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPlan,
                decoration: const InputDecoration(
                  labelText: 'Subscription Plan',
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'plan_100', child: Text('Basic (100 Scans)')),
                  DropdownMenuItem(
                      value: 'plan_250', child: Text('Standard (250 Scans)')),
                  DropdownMenuItem(
                      value: 'plan_unlimited',
                      child: Text('Premium (Unlimited)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedPlan = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (days)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (selectedRestaurantId.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please select a restaurant',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                try {
                  // Parse duration
                  final duration =
                      int.tryParse(durationController.text.trim()) ?? 30;

                  // Calculate start and end dates
                  final now = DateTime.now();
                  final endDate = now.add(Duration(days: duration));

                  // Update subscription in Firestore
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(selectedRestaurantId)
                      .update({
                    'subscriptionPlan': selectedPlan,
                    'subscriptionStatus': 'active',
                    'subscriptionStart': Timestamp.fromDate(now),
                    'subscriptionEnd': Timestamp.fromDate(endDate),
                    'paymentStatus': 'paid', // Assume payment is made
                  });

                  // Record subscription transaction
                  await FirebaseFirestore.instance
                      .collection('subscriptions')
                      .add({
                    'restaurantId': selectedRestaurantId,
                    'plan': selectedPlan,
                    'startDate': Timestamp.fromDate(now),
                    'endDate': Timestamp.fromDate(endDate),
                    'amountPaid': _getPlanAmount(selectedPlan),
                    'duration': duration,
                    'timestamp': Timestamp.fromDate(now),
                  });

                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Subscription created successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to create subscription: $e',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Create'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDetails(
      BuildContext context, String restaurantId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final subscriptionPlan = data['subscriptionPlan'] ?? 'No plan';
    final subscriptionStatus = data['subscriptionStatus'] ?? 'inactive';
    final paymentStatus = data['paymentStatus'] ?? 'unpaid';

    final startDate = data['subscriptionStart'] != null
        ? (data['subscriptionStart'] as Timestamp).toDate()
        : null;

    final endDate = data['subscriptionEnd'] != null
        ? (data['subscriptionEnd'] as Timestamp).toDate()
        : null;

    Get.dialog(
      AlertDialog(
        title: Text('$name - Subscription'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Plan', _formatPlanName(subscriptionPlan)),
              _buildDetailRow('Status', subscriptionStatus),
              _buildDetailRow('Payment Status', paymentStatus.toUpperCase()),
              _buildDetailRow(
                  'Start Date',
                  startDate != null
                      ? DateFormat('dd/MM/yyyy').format(startDate)
                      : 'N/A'),
              _buildDetailRow(
                  'End Date',
                  endDate != null
                      ? DateFormat('dd/MM/yyyy').format(endDate)
                      : 'N/A'),
              if (endDate != null)
                _buildDetailRow(
                  'Days Remaining',
                  _getRemainingDays(endDate),
                ),
              const Divider(),
              const Text(
                'Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _showRenewDialog(context, restaurantId, data);
                      },
                      child: const Text(
                        'Renew',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _cancelSubscription(restaurantId),
                      child: const Text(
                        'Cancel Subscription',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getRemainingDays(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference > 0 ? '$difference days' : 'Expired';
  }

  double _getPlanAmount(String plan) {
    // Get from subscription_plans collection instead of hardcoded values
    switch (plan) {
      case 'plan_100':
        return controller.planPrices['plan_100'] ?? 99.99;
      case 'plan_250':
        return controller.planPrices['plan_250'] ?? 199.99;
      case 'plan_unlimited':
        return controller.planPrices['plan_unlimited'] ?? 299.99;
      default:
        return 0.0;
    }
  }

  Future<void> _cancelSubscription(String restaurantId) async {
    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .update({
        'subscriptionStatus': 'inactive',
      });

      Get.back(); // Close the details dialog
      Get.snackbar(
        'Success',
        'Subscription cancelled successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel subscription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
