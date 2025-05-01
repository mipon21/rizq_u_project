import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/admin_controller.dart';

class RestaurantManagementPage extends GetView<AdminController> {
  const RestaurantManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Restaurants',
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
                  return const Center(child: Text('No restaurants found'));
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
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Subscription')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Unknown';
                              final email = data['email'] ?? 'No email';
                              final subscriptionPlan =
                                  data['subscriptionPlan'] ?? 'No plan';
                              final subscriptionStatus =
                                  data['subscriptionStatus'] ?? 'inactive';
                              final isSuspended = data['isSuspended'] ?? false;

                              return DataRow(
                                cells: [
                                  DataCell(Text(name)),
                                  DataCell(Text(email)),
                                  DataCell(Text(subscriptionPlan)),
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
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _showEditDialog(
                                            context, doc.id, data),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isSuspended
                                              ? Icons.check_circle
                                              : Icons.block,
                                          color: isSuspended
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        onPressed: () => _toggleSuspension(
                                            doc.id, isSuspended),
                                        tooltip: isSuspended
                                            ? 'Unsuspend'
                                            : 'Suspend',
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
                          final isSuspended = data['isSuspended'] ?? false;

                          return ListTile(
                            title: Text(name),
                            subtitle: Text('Plan: $subscriptionPlan'),
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
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () =>
                                      _showEditDialog(context, doc.id, data),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isSuspended
                                        ? Icons.check_circle
                                        : Icons.block,
                                    color:
                                        isSuspended ? Colors.green : Colors.red,
                                  ),
                                  onPressed: () =>
                                      _toggleSuspension(doc.id, isSuspended),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showRestaurantDetails(context, doc.id, data),
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
    );
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

  Future<void> _toggleSuspension(
      String restaurantId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .update({
        'isSuspended': !currentStatus,
      });

      Get.snackbar(
        'Success',
        'Restaurant ${currentStatus ? 'un-suspended' : 'suspended'} successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update restaurant status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showEditDialog(
      BuildContext context, String restaurantId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final addressController =
        TextEditingController(text: data['address'] ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Restaurant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: data['subscriptionPlan'] ?? 'free_trial',
                decoration: const InputDecoration(
                  labelText: 'Subscription Plan',
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'free_trial', child: Text('Free Trial')),
                  DropdownMenuItem(
                      value: 'plan_100', child: Text('Basic (100 Scans)')),
                  DropdownMenuItem(
                      value: 'plan_250', child: Text('Standard (250 Scans)')),
                  DropdownMenuItem(
                      value: 'plan_unlimited',
                      child: Text('Premium (Unlimited)')),
                ],
                onChanged: (value) {
                  // Update selected plan
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: data['subscriptionStatus'] ?? 'inactive',
                decoration: const InputDecoration(
                  labelText: 'Subscription Status',
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(
                      value: 'free_trial', child: Text('Free Trial')),
                ],
                onChanged: (value) {
                  // Update selected status
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
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('restaurants')
                    .doc(restaurantId)
                    .update({
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  // Add other fields from dropdowns
                });

                Get.back();
                Get.snackbar(
                  'Success',
                  'Restaurant updated successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to update restaurant: $e',
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

  void _showRestaurantDetails(
      BuildContext context, String restaurantId, Map<String, dynamic> data) {
    Get.dialog(
      AlertDialog(
        title: Text(data['name'] ?? 'Restaurant Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', data['email'] ?? 'No email'),
              _buildDetailRow('Address', data['address'] ?? 'No address'),
              _buildDetailRow('Phone', data['phone'] ?? 'No phone'),
              _buildDetailRow(
                  'Subscription Plan', data['subscriptionPlan'] ?? 'No plan'),
              _buildDetailRow('Subscription Status',
                  data['subscriptionStatus'] ?? 'inactive'),
              _buildDetailRow(
                  'Total Scans', '${data['currentScanCount'] ?? 0}'),
              _buildDetailRow(
                  'Created At',
                  data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate().toString()
                      : 'Unknown'),
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
