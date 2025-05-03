import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/admin_controller.dart';

class RestaurantManagementPage extends GetView<AdminController> {
  const RestaurantManagementPage({Key? key}) : super(key: key);

  // Override the controller getter to ensure it's properly initialized
  @override
  AdminController get controller {
    if (!Get.isRegistered<AdminController>()) {
      Get.put(AdminController(), permanent: true);
    }
    return Get.find<AdminController>();
  }

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
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: DefaultTabController(
            length: 3, // Changed from 2 to 3 tabs
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Restaurant Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const TabBar(
                  tabs: [
                    Tab(text: 'Info'),
                    Tab(text: 'Subscription'),
                    Tab(text: 'Loyalty Program'), // New tab
                  ],
                  labelColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      // Info tab content
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Email', data['email'] ?? 'Not set'),
                            _buildInfoRow('Phone', data['phone'] ?? 'Not set'),
                            _buildInfoRow(
                                'Address', data['address'] ?? 'Not set'),
                            _buildInfoRow(
                                'Owner', data['ownerName'] ?? 'Not set'),
                            _buildInfoRow(
                                'Status',
                                data['isSuspended'] == true
                                    ? 'Suspended'
                                    : 'Active'),
                            _buildInfoRow(
                                'Created', _formatTimestamp(data['createdAt'])),
                            const SizedBox(height: 16),
                            if (data['logoUrl'] != null &&
                                data['logoUrl'].isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Logo:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Image.network(
                                    data['logoUrl'],
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 80,
                                        width: 80,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Text('No Image'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Subscription tab content
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                                'Plan', data['subscriptionPlan'] ?? 'Not set'),
                            _buildInfoRow('Status',
                                data['subscriptionStatus'] ?? 'inactive'),
                            _buildInfoRow('Started',
                                _formatTimestamp(data['subscriptionStart'])),
                            _buildInfoRow('Expires',
                                _formatTimestamp(data['subscriptionEnd'])),
                            _buildInfoRow('Auto-Renew',
                                (data['autoRenew'] == true) ? 'Yes' : 'No'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _showManageSubscriptionDialog(
                                  context, restaurantId, data),
                              child: const Text('Manage Subscription'),
                            ),
                          ],
                        ),
                      ),
                      // Loyalty Program tab content (new)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('programs')
                            .doc(restaurantId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          final programData =
                              snapshot.data?.data() as Map<String, dynamic>?;

                          if (programData == null) {
                            return const Center(
                              child: Text(
                                  'No loyalty program found for this restaurant'),
                            );
                          }

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Reward Type',
                                    programData['rewardType'] ?? 'Not set'),
                                _buildInfoRow('Points Required',
                                    '${programData['pointsRequired'] ?? 10}'),
                                _buildInfoRow('Created',
                                    _formatTimestamp(programData['createdAt'])),
                                const SizedBox(height: 16),
                                const Text(
                                  'Reward Claims:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                FutureBuilder<int>(
                                  future:
                                      _getRestaurantClaimCount(restaurantId),
                                  builder: (context, claimSnapshot) {
                                    if (claimSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text(
                                          'Loading claim data...');
                                    }

                                    final claimCount = claimSnapshot.data ?? 0;
                                    return Text(
                                      'Total rewards claimed: $claimCount',
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () =>
                                      _showEditLoyaltyProgramDialog(
                                          context, restaurantId, programData),
                                  child: const Text('Edit Loyalty Program'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString();
    } else if (timestamp is String) {
      return timestamp;
    } else {
      throw Exception('Invalid timestamp format');
    }
  }

  Future<int> _getRestaurantClaimCount(String restaurantId) async {
    final claimsSnapshot = await FirebaseFirestore.instance
        .collection('claims')
        .where('restaurantId', isEqualTo: restaurantId)
        .count()
        .get();

    return claimsSnapshot.count ?? 0;
  }

  void _showEditLoyaltyProgramDialog(BuildContext context, String restaurantId,
      Map<String, dynamic> programData) {
    final rewardTypeController =
        TextEditingController(text: programData['rewardType'] ?? '');
    final pointsRequiredController =
        TextEditingController(text: '${programData['pointsRequired'] ?? 10}');

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Loyalty Program'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rewardTypeController,
                decoration: const InputDecoration(
                  labelText: 'Reward Type',
                  hintText: 'e.g., Free Coffee, Dessert Offer, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsRequiredController,
                decoration: const InputDecoration(
                  labelText: 'Points Required',
                  hintText: 'e.g., 10',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rewardType = rewardTypeController.text.trim();
              final pointsRequired =
                  int.tryParse(pointsRequiredController.text.trim()) ?? 10;

              if (rewardType.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please enter a reward type',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('programs')
                    .doc(restaurantId)
                    .update({
                  'rewardType': rewardType,
                  'pointsRequired': pointsRequired,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                Get.back(); // Close the dialog
                Get.snackbar(
                  'Success',
                  'Loyalty program updated successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );

                // Refresh the dialog
                Navigator.of(context).pop();
                _showRestaurantDetails(
                    context,
                    restaurantId,
                    (await FirebaseFirestore.instance
                                .collection('restaurants')
                                .doc(restaurantId)
                                .get())
                            .data() ??
                        {});
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to update loyalty program: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  // Add the missing subscription management dialog
  void _showManageSubscriptionDialog(
      BuildContext context, String restaurantId, Map<String, dynamic> data) {
    final planController =
        TextEditingController(text: data['subscriptionPlan'] ?? 'Basic');
    final statusController =
        TextEditingController(text: data['subscriptionStatus'] ?? 'inactive');

    // For date pickers
    DateTime startDate =
        (data['subscriptionStart'] as Timestamp?)?.toDate() ?? DateTime.now();
    DateTime endDate = (data['subscriptionEnd'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(days: 30));

    // For auto-renew checkbox
    bool autoRenew = data['autoRenew'] ?? false;

    Get.dialog(
      AlertDialog(
        title: const Text('Manage Subscription'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Subscription Plan',
                  border: OutlineInputBorder(),
                ),
                value: planController.text,
                items: const [
                  DropdownMenuItem(value: 'Basic', child: Text('Basic')),
                  DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                  DropdownMenuItem(
                      value: 'Enterprise', child: Text('Enterprise')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    planController.text = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: statusController.text,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(
                      value: 'free_trial', child: Text('Free Trial')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    statusController.text = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Auto-Renew'),
                trailing: Switch(
                  value: autoRenew,
                  onChanged: (value) {
                    autoRenew = value;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('restaurants')
                    .doc(restaurantId)
                    .update({
                  'subscriptionPlan': planController.text,
                  'subscriptionStatus': statusController.text,
                  'autoRenew': autoRenew,
                  'subscriptionStart': Timestamp.fromDate(startDate),
                  'subscriptionEnd': Timestamp.fromDate(endDate),
                });

                Get.back(); // Close the dialog
                Get.snackbar(
                  'Success',
                  'Subscription updated successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );

                // Refresh the dialog
                Navigator.of(context).pop();
                _showRestaurantDetails(
                    context,
                    restaurantId,
                    (await FirebaseFirestore.instance
                                .collection('restaurants')
                                .doc(restaurantId)
                                .get())
                            .data() ??
                        {});
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to update subscription: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
