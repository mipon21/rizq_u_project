import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import '../../../ui/theme/widget_themes/cached_image_widget.dart';
import '../../../ui/theme/widget_themes/shimmer_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        backgroundColor: MColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => controller.exportRestaurantsToCSV(),
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
            tooltip: 'Filter',
          ),
        ],
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
                controller.searchRestaurants(value);
              },
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Obx(() => Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Active', 'active'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Inactive', 'inactive'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Suspended', 'suspended'),
                  ],
                )),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Obx(() => StreamBuilder<QuerySnapshot>(
                  stream: controller.getFilteredRestaurantsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ShimmerListView(
                          itemCount: 5,
                          itemHeight: 80,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No restaurants found'));
                    }

                    // Filter by search query if provided
                    var filteredDocs = snapshot.data!.docs;
                    if (controller.restaurantSearchQuery.isNotEmpty) {
                      final query =
                          controller.restaurantSearchQuery.value.toLowerCase();
                      filteredDocs = filteredDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name =
                            (data['name'] ?? '').toString().toLowerCase();
                        final email =
                            (data['email'] ?? '').toString().toLowerCase();
                        final phone =
                            (data['phone'] ?? '').toString().toLowerCase();
                        return name.contains(query) ||
                            email.contains(query) ||
                            phone.contains(query);
                      }).toList();
                    }

                    if (filteredDocs.isEmpty) {
                      return const Center(
                          child: Text('No restaurants match your search'));
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
                                  DataColumn(label: Text('Approval')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: filteredDocs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final name = data['name'] ?? 'Unknown';
                                  final email = data['email'] ?? 'No email';
                                  final subscriptionPlan =
                                      data['subscriptionPlan'] ?? 'No plan';
                                  final subscriptionStatus =
                                      data['subscriptionStatus'] ?? 'inactive';
                                  final isSuspended =
                                      data['isSuspended'] ?? false;
                                  final approvalStatus =
                                      data['approvalStatus'] ?? 'pending';

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
                                          backgroundColor: _getStatusColor(
                                              subscriptionStatus),
                                        ),
                                      ),
                                      DataCell(
                                        Chip(
                                          label: Text(
                                            approvalStatus,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor:
                                              _getApprovalStatusColor(
                                                  approvalStatus),
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
                                          if (approvalStatus == 'pending')
                                            IconButton(
                                              icon: const Icon(Icons.check,
                                                  color: Colors.green),
                                              onPressed: () => controller
                                                  .approveRestaurant(doc.id),
                                              tooltip: 'Approve',
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
                            itemCount: filteredDocs.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Unknown';
                              final subscriptionPlan =
                                  data['subscriptionPlan'] ?? 'No plan';
                              final subscriptionStatus =
                                  data['subscriptionStatus'] ?? 'inactive';
                              final isSuspended = data['isSuspended'] ?? false;
                              final approvalStatus =
                                  data['approvalStatus'] ?? 'pending';

                              return ListTile(
                                title: Text(name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Plan: $subscriptionPlan'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(
                                            subscriptionStatus,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                          backgroundColor: _getStatusColor(
                                              subscriptionStatus),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text(
                                            approvalStatus,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                          backgroundColor:
                                              _getApprovalStatusColor(
                                                  approvalStatus),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _showEditDialog(
                                          context, doc.id, data),
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
                                    ),
                                  ],
                                ),
                                onTap: () => _showRestaurantDetails(
                                    context, doc.id, data),
                                isThreeLine: true,
                              );
                            },
                          );
                        }
                      },
                    );
                  },
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRestaurantDialog(context),
        backgroundColor: MColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = controller.selectedRestaurantFilter.value == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          controller.filterRestaurants(value);
        } else {
          controller.filterRestaurants('all');
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: MColors.primary.withOpacity(0.2),
      checkmarkColor: MColors.primary,
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Restaurants',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Status'),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Active', 'active'),
                      _buildFilterChip('Inactive', 'inactive'),
                      _buildFilterChip('Pending', 'pending'),
                      _buildFilterChip('Suspended', 'suspended'),
                    ],
                  )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      controller.filterRestaurants('all');
                      controller.searchRestaurants('');
                      Get.back();
                    },
                    child: const Text('Reset Filters'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  Color _getApprovalStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
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
    final nameController = TextEditingController(text: data['name']);
    final emailController = TextEditingController(text: data['email']);
    final phoneController = TextEditingController(text: data['phone']);
    final addressController = TextEditingController(text: data['address']);
    final subscriptionPlanController =
        TextEditingController(text: data['subscriptionPlan']);
    final subscriptionStatusController =
        TextEditingController(text: data['subscriptionStatus']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${data['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: subscriptionPlanController,
                  decoration:
                      const InputDecoration(labelText: 'Subscription Plan'),
                ),
                TextField(
                  controller: subscriptionStatusController,
                  decoration:
                      const InputDecoration(labelText: 'Subscription Status'),
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
                    'name': nameController.text,
                    'email': emailController.text,
                    'phone': phoneController.text,
                    'address': addressController.text,
                    'subscriptionPlan': subscriptionPlanController.text,
                    'subscriptionStatus': subscriptionStatusController.text,
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
        );
      },
    );
  }

  void _showRestaurantDetails(
      BuildContext context, String restaurantId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'No email';
    final phone = data['phone'] ?? 'No phone';
    final address = data['address'] ?? 'No address';
    final subscriptionPlan = data['subscriptionPlan'] ?? 'No plan';
    final subscriptionStatus = data['subscriptionStatus'] ?? 'inactive';
    final isSuspended = data['isSuspended'] ?? false;
    final approvalStatus = data['approvalStatus'] ?? 'pending';
    final logoUrl = data['logoUrl'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: logoUrl != null
                      ? CachedImageWidget(
                          imageUrl: logoUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(50),
                        )
                      : const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.restaurant, size: 50),
                        ),
                ),
                const SizedBox(height: 16),
                _detailRow('Email', email),
                _detailRow('Phone', phone),
                _detailRow('Address', address),
                _detailRow('Subscription Plan', subscriptionPlan),
                _detailRow('Subscription Status', subscriptionStatus,
                    color: _getStatusColor(subscriptionStatus)),
                _detailRow(
                    'Account Status', isSuspended ? 'Suspended' : 'Active',
                    color: isSuspended ? Colors.red : Colors.green),
                _detailRow('Approval Status', approvalStatus,
                    color: _getApprovalStatusColor(approvalStatus)),
              ],
            ),
          ),
          actions: [
            if (approvalStatus == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('Approve'),
                    onPressed: () {
                      Get.back();
                      controller.approveRestaurant(restaurantId);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject'),
                    onPressed: () {
                      Get.back();
                      _showRejectDialog(context, restaurantId);
                    },
                  ),
                ],
              ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _showEditDialog(context, restaurantId, data);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, String restaurantId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Restaurant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please provide a reason for rejection',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                Get.back();
                controller.rejectRestaurant(
                    restaurantId, reasonController.text.trim());
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRestaurantDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Restaurant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Restaurant Name *'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password *'),
                  obscureText: true,
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
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
                if (nameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    passwordController.text.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please fill in all required fields',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                try {
                  // Create user with email and password
                  final userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                  );

                  // Create restaurant document
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(userCredential.user!.uid)
                      .set({
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'address': addressController.text.trim(),
                    'subscriptionPlan': 'free_trial',
                    'subscriptionStatus': 'inactive',
                    'isSuspended': false,
                    'approvalStatus': 'approved',
                    'createdAt': Timestamp.now(),
                    'approvedAt': Timestamp.now(),
                  });

                  // Create user document with role
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userCredential.user!.uid)
                      .set({
                    'email': emailController.text.trim(),
                    'role': 'restaurateur',
                    'createdAt': Timestamp.now(),
                  });

                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Restaurant added successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to add restaurant: $e',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
