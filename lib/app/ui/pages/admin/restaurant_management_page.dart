import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import '../../../ui/theme/widget_themes/cached_image_widget.dart';
import '../../../ui/theme/widget_themes/shimmer_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/subscription_plan_model.dart';
import 'package:intl/intl.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;
    final isTablet = screenWidth > 600 && screenWidth <= 1000;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Management'),
        backgroundColor: MColors.primary,
        actions: [
          // Debug: Show restaurant counts
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => _showRestaurantCounts(context),
              tooltip: 'Show Restaurant Info (Debug)',
            ),
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

                    // Debug: Log restaurant data
                    if (kDebugMode) {
                      print('📊 Restaurant Management Page Data:');
                      print('   - Total restaurants loaded: ${snapshot.data!.docs.length}');
                      final approvalStatuses = <String, int>{};
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['approvalStatus'] ?? 'unknown';
                        approvalStatuses[status] = (approvalStatuses[status] ?? 0) + 1;
                      }
                      approvalStatuses.forEach((status, count) {
                        print('   - $status: $count restaurants');
                      });
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
                                  DataColumn(label: Text('Expiry Date')),
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
                                  final subscriptionEndDate = data['subscriptionEnd'] as Timestamp?;
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
                                      DataCell(Text(_getPlanDisplayName(
                                          subscriptionPlan))),
                                      DataCell(Text(_formatExpiryDate(subscriptionEndDate))),
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
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
                                            if (isSuspended)
                                              const Chip(
                                                label: Text(
                                                  'SUSPENDED',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                          ],
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
                                            icon: const Icon(
                                                Icons.subscriptions,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _showAssignSubscriptionDialog(
                                                    context, doc.id, data),
                                            tooltip: 'Assign Plan',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.visibility,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _showRestaurantDetails(
                                              context,
                                              doc.id,
                                              data,
                                            ),
                                            tooltip: 'View Details',
                                          ),
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
                              final subscriptionEndDate = data['subscriptionEnd'] as Timestamp?;
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
                                    Text(
                                        'Plan: ${_getPlanDisplayName(subscriptionPlan)}'),
                                    Text(
                                        'Expires: ${_formatExpiryDate(subscriptionEndDate)}'),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
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
                                        if (isSuspended)
                                          const Chip(
                                            label: Text(
                                              'SUSPENDED',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
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
                                      icon: const Icon(Icons.subscriptions,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _showAssignSubscriptionDialog(
                                              context, doc.id, data),
                                      tooltip: 'Assign Plan',
                                    ),
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
                                    if (isDesktop)
                                      IconButton(
                                        icon: const Icon(
                                            Icons.panorama_fish_eye,
                                            color: Colors.blue),
                                        onPressed: () => _showRestaurantDetails(
                                            context, doc.id, data),
                                        tooltip: 'View Details',
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
    // Initialize controllers with current data
    final restaurantNameController = TextEditingController(text: data['restaurantName'] ?? data['name'] ?? '');
    final ownerNameController = TextEditingController(text: data['ownerName'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');
    final supportEmailController = TextEditingController(text: data['supportEmail'] ?? '');
    final bankDetailsController = TextEditingController(text: data['bankDetails'] ?? '');
    final ibanController = TextEditingController(text: data['ibanNumber'] ?? '');
    
    // Non-editable display data
    final logoUrl = data['logoUrl'] ?? '';
    final nationalIdFront = data['ownerNationalIdFront'] ?? '';
    final nationalIdBack = data['ownerNationalIdBack'] ?? '';
    final createdAt = data['createdAt'];
    final approvalStatus = data['approvalStatus'] ?? 'unknown';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Restaurant: ${data['restaurantName'] ?? data['name'] ?? 'Unknown'}'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Logo (Display Only)
                  if (logoUrl.isNotEmpty) ...[
                    const Text(
                      'Restaurant Logo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedImageWidget(
                          imageUrl: logoUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Restaurant Information Section
                  const Text(
                    'Restaurant Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: restaurantNameController,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ownerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Owner Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact Information Section
                  const Text(
                    'Contact Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Primary Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: supportEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Support Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.support_agent),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Bank Information Section
                  const Text(
                    'Bank Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bankDetailsController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Details',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ibanController,
                    decoration: const InputDecoration(
                      labelText: 'IBAN Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Information (Read-Only)
                  const Text(
                    'Account Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Restaurant ID', restaurantId),
                        _buildInfoRow('Approval Status', approvalStatus.toUpperCase()),
                        if (createdAt != null)
                          _buildInfoRow('Registration Date', 
                            (createdAt as Timestamp).toDate().toString().split(' ')[0]),
                      ],
                    ),
                  ),

                  // National ID Documents (Display Only)
                  if (nationalIdFront.isNotEmpty || nationalIdBack.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Owner Identity Documents (View Only)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (nationalIdFront.isNotEmpty)
                          Expanded(
                            child: Column(
                              children: [
                                const Text('National ID - Front'),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedImageWidget(
                                    imageUrl: nationalIdFront,
                                    width: double.infinity,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (nationalIdFront.isNotEmpty && nationalIdBack.isNotEmpty)
                          const SizedBox(width: 16),
                        if (nationalIdBack.isNotEmpty)
                          Expanded(
                            child: Column(
                              children: [
                                const Text('National ID - Back'),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedImageWidget(
                                    imageUrl: nationalIdBack,
                                    width: double.infinity,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate required fields
                if (restaurantNameController.text.trim().isEmpty ||
                    ownerNameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Validation Error',
                    'Please fill in all required fields (marked with *)',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                try {
                  // Update restaurant document with comprehensive data
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .update({
                    'restaurantName': restaurantNameController.text.trim(),
                    'name': restaurantNameController.text.trim(), // Keep both for compatibility
                    'ownerName': ownerNameController.text.trim(),
                    'email': emailController.text.trim(),
                    'supportEmail': supportEmailController.text.trim(),
                    'bankDetails': bankDetailsController.text.trim(),
                    'ibanNumber': ibanController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Restaurant information updated successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );

                  if (kDebugMode) {
                    print('Restaurant updated: ${restaurantNameController.text}');
                    print('Owner: ${ownerNameController.text}');
                    print('Email: ${emailController.text}');
                  }
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
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestaurantDetails(
      BuildContext context, String restaurantId, Map<String, dynamic> data) {
    // Extract all data fields
    final restaurantName = data['restaurantName'] ?? data['name'] ?? 'Unknown';
    final ownerName = data['ownerName'] ?? 'Not provided';
    final email = data['email'] ?? 'Not provided';
    final supportEmail = data['supportEmail'] ?? 'Not provided';
    final bankDetails = data['bankDetails'] ?? 'Not provided';
    final ibanNumber = data['ibanNumber'] ?? 'Not provided';
    final isSuspended = data['isSuspended'] ?? false;
    final approvalStatus = data['approvalStatus'] ?? 'pending';
    final createdAt = data['createdAt'];
    final logoUrl = data['logoUrl'] ?? '';
    final nationalIdFront = data['ownerNationalIdFront'] ?? '';
    final nationalIdBack = data['ownerNationalIdBack'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Restaurant Details: $restaurantName'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Logo (Display Only)
                  if (logoUrl.isNotEmpty) ...[
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedImageWidget(
                          imageUrl: logoUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Restaurant Information Section
                  _buildSectionTitle('Restaurant Information'),
                  const SizedBox(height: 8),
                  _buildInfoCard([
                    _buildDetailRow('Restaurant Name', restaurantName),
                    _buildDetailRow('Owner Name', ownerName),
                  ]),
                  const SizedBox(height: 16),

                  // Contact Information Section
                  _buildSectionTitle('Contact Information'),
                  const SizedBox(height: 8),
                  _buildInfoCard([
                    _buildDetailRow('Primary Email', email),
                    if (supportEmail != null &&
                        supportEmail != 'Not provided' &&
                        supportEmail.isNotEmpty)
                      _buildDetailRow('Support Email', supportEmail),
                  ]),
                  const SizedBox(height: 16),

                  // Bank Information Section (only show if data exists)
                  if ((bankDetails != null &&
                          bankDetails != 'Not provided' &&
                          bankDetails.isNotEmpty) ||
                      (ibanNumber != null &&
                          ibanNumber != 'Not provided' &&
                          ibanNumber.isNotEmpty)) ...[
                    _buildSectionTitle('Bank Information'),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      if (bankDetails != null &&
                          bankDetails != 'Not provided' &&
                          bankDetails.isNotEmpty)
                        _buildDetailRow('Bank Details', bankDetails),
                      if (ibanNumber != null &&
                          ibanNumber != 'Not provided' &&
                          ibanNumber.isNotEmpty)
                        _buildDetailRow('IBAN Number', ibanNumber),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // Account Information Section
                  _buildSectionTitle('Account Information'),
                  const SizedBox(height: 8),
                  _buildInfoCard([
                    _buildDetailRow('Restaurant ID', restaurantId),
                    _buildDetailRow('Account Status', 
                      isSuspended ? 'Suspended' : 'Active',
                      valueColor: isSuspended ? Colors.red : Colors.green),
                    _buildDetailRow('Approval Status', approvalStatus.toUpperCase(),
                      valueColor: _getApprovalStatusColor(approvalStatus)),
                    if (createdAt != null)
                      _buildDetailRow('Registration Date', 
                        (createdAt as Timestamp).toDate().toString().split(' ')[0]),
                  ]),

                  // National ID Documents (Display Only)
                  if (nationalIdFront.isNotEmpty || nationalIdBack.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Owner Identity Documents'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (nationalIdFront.isNotEmpty)
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'National ID - Front',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedImageWidget(
                                    imageUrl: nationalIdFront,
                                    width: double.infinity,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (nationalIdFront.isNotEmpty && nationalIdBack.isNotEmpty)
                          const SizedBox(width: 16),
                        if (nationalIdBack.isNotEmpty)
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'National ID - Back',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedImageWidget(
                                    imageUrl: nationalIdBack,
                                    width: double.infinity,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            // Action buttons in a more organized layout
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Approve/Reject buttons (only for pending restaurants)
                if (approvalStatus == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Get.back();
                              controller.approveRestaurant(restaurantId);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Get.back();
                              _showRejectDialog(context, restaurantId);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Main action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.subscriptions, color: Colors.blue),
                        label: const Text('Assign Plan'),
                        onPressed: () {
                          Get.back();
                          _showAssignSubscriptionDialog(context, restaurantId, data);
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.schedule, color: Colors.orange),
                        label: const Text('Extend'),
                        onPressed: () {
                          Get.back();
                          _showExtendSubscriptionDialog(context, restaurantId);
                        },
                      ),
                    ),
                  ],
                ),
                
                // Bottom action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Close'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          _showEditDialog(context, restaurantId, data);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
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
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRestaurantDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Restaurant Login Credentials'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create login credentials for a new restaurant. The restaurant owner will use these credentials to login and complete their registration process.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    helperText: 'This will be used as the restaurant login email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'Minimum 6 characters',
                  ),
                  obscureText: true,
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
                if (emailController.text.trim().isEmpty ||
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

                if (passwordController.text.length < 6) {
                  Get.snackbar(
                    'Error',
                    'Password must be at least 6 characters long',
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

                  // Create user document with role (minimal setup)
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userCredential.user!.uid)
                      .set({
                    'email': emailController.text.trim(),
                    'role': 'restaurateur',
                    'createdAt': Timestamp.now(),
                    'createdByAdmin': true, // Flag to indicate admin created this account
                  });

                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Restaurant login credentials created successfully!\nThe restaurant can now login and complete their registration.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );

                  if (kDebugMode) {
                    print('✅ Restaurant credentials created:');
                    print('   - Email: ${emailController.text.trim()}');
                    print('   - User ID: ${userCredential.user!.uid}');
                    print('   - Restaurant can now login and complete registration');
                  }
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to create restaurant credentials: $e',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Credentials'),
            ),
          ],
        );
      },
    );
  }

  void _showAssignSubscriptionDialog(BuildContext context, String restaurantId,
      Map<String, dynamic> restaurantData) {
    final selectedPlan = Rx<SubscriptionPlanModel?>(null);
    final durationDays = RxInt(30);
    final resetScans = RxBool(true);

    Get.dialog(
      AlertDialog(
        title: Text(
            'Assign Subscription to ${restaurantData['name'] ?? 'Unknown'}'),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.isAssigningSubscription.value)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<SubscriptionPlanModel>(
                        decoration: const InputDecoration(
                          labelText: 'Select Subscription Plan',
                        ),
                        value: selectedPlan.value,
                        items: controller.activeSubscriptionPlans
                            .map((plan) => DropdownMenuItem(
                                  value: plan,
                                  child: Text(plan.name),
                                ))
                            .toList(),
                        onChanged: (plan) => selectedPlan.value = plan,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Duration (days)',
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: durationDays.toString(),
                        onChanged: (value) =>
                            durationDays.value = int.tryParse(value) ?? 30,
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Reset Scan Count'),
                        subtitle: const Text(
                            'Start fresh scan count for new subscription'),
                        value: resetScans.value,
                        onChanged: (value) => resetScans.value = value ?? true,
                      ),
                    ],
                  ),
              ],
            )),
        actions: [
          TextButton(
            onPressed: controller.isAssigningSubscription.value
                ? null
                : () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: controller.isAssigningSubscription.value
                ? null
                : () async {
                    if (selectedPlan.value == null) {
                      Get.snackbar(
                        'Error',
                        'Please select a subscription plan',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    await controller.assignSubscriptionPlan(
                      restaurantId: restaurantId,
                      planId: selectedPlan.value!.id,
                      durationDays: durationDays.value,
                      resetScans: resetScans.value,
                    );

                    Get.back();
                  },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showExtendSubscriptionDialog(
      BuildContext context, String restaurantId) {
    int additionalDays = 30;

    Get.dialog(
      AlertDialog(
        title: const Text('Extend Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the number of days to extend the subscription:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Additional Days',
                border: OutlineInputBorder(),
                hintText: '30',
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(
                text: additionalDays.toString(),
              ),
              onChanged: (value) {
                final days = int.tryParse(value);
                if (days != null && days > 0) {
                  additionalDays = days;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.extendRestaurantSubscription(
                restaurantId: restaurantId,
                additionalDays: additionalDays,
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  String _getPlanDisplayName(String planId) {
    // Handle free trial
    if (planId == 'free_trial') {
      return 'Free Trial';
    }

    // Look up custom plans
    SubscriptionPlanModel? plan;
    if (controller.subscriptionPlans.isNotEmpty) {
      try {
        plan = controller.subscriptionPlans.firstWhere((p) => p.id == planId);
      } catch (e) {
        plan = null;
      }
    }

    if (plan != null) return plan.name;

    // Fallback for unknown plans
    return planId;
  }

  // Debug method to show restaurant counts by approval status
  void _showRestaurantCounts(BuildContext context) async {
    try {
      // Get all restaurants from restaurants collection
      final restaurantsSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .get();

      // Get pending registrations from restaurant_registrations collection
      final pendingSnapshot = await FirebaseFirestore.instance
          .collection('restaurant_registrations')
          .where('approvalStatus', isEqualTo: 'pending')
          .get();

      // Count by approval status
      final approvalCounts = <String, int>{};
      for (var doc in restaurantsSnapshot.docs) {
        final data = doc.data();
        final status = data['approvalStatus'] ?? 'unknown';
        approvalCounts[status] = (approvalCounts[status] ?? 0) + 1;
      }

      Get.dialog(
        AlertDialog(
          title: const Text('Restaurant Status Overview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restaurants Collection (Restaurant Management):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• Total: ${restaurantsSnapshot.docs.length}'),
              ...approvalCounts.entries.map((entry) =>
                  Text('• ${entry.key}: ${entry.value}')),
              const SizedBox(height: 16),
              Text(
                'Restaurant Registrations Collection (Pending Approvals):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• Pending: ${pendingSnapshot.docs.length}'),
              const SizedBox(height: 16),
              const Text(
                '💡 When you approve a restaurant:\n'
                '• It disappears from Pending Approvals\n'
                '• It appears in Restaurant Management\n'
                '• Filter is set to "All" by default',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch restaurant counts: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _formatExpiryDate(Timestamp? subscriptionEndDate) {
    if (subscriptionEndDate == null) {
      return 'No expiry';
    }
    
    final DateTime expiryDate = subscriptionEndDate.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = expiryDate.difference(now);
    
    // Format the date
    final String formattedDate = DateFormat('MMM dd, yyyy').format(expiryDate);
    
    if (difference.isNegative) {
      final int daysExpired = difference.inDays.abs();
      return '$formattedDate (Expired $daysExpired days ago)';
    } else if (difference.inDays == 0) {
      return '$formattedDate (Expires today)';
    } else if (difference.inDays <= 7) {
      return '$formattedDate (${difference.inDays} days left)';
    } else {
      return formattedDate;
    }
  }
}
