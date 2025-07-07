import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../utils/constants/colors.dart';
import '../../../controllers/admin_controller.dart';

class CustomerManagementPage extends GetView<AdminController> {
  const CustomerManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;
    final isTablet = screenWidth > 600 && screenWidth <= 1000;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: MColors.primary,
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () => controller.exportCustomersToCSV(),
              tooltip: 'Export Data',
            ),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Column(
          children: [
            // Search and filter section with responsive padding
            Padding(
              padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
              child: isDesktop || isTablet
                  ? Row(
                      children: [
                        // Search field takes most of the space
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Search Customers',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            onChanged: (value) {
                              // Implement search functionality
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Export button for desktop
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_download),
                          label: const Text('Export'),
                          onPressed: () => controller.exportCustomersToCSV(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // Search field
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Search Customers',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            // Implement search functionality
                          },
                        ),
                      ],
                    ),
            ),

            // Main content area
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'customer')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No customers found'));
                  }

                  // Desktop/tablet view with data table
                  if (isDesktop || isTablet) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'All Customers',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${snapshot.data!.docs.length} customers',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade100,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Name')),
                                    DataColumn(label: Text('Email')),
                                    DataColumn(label: Text('Joined Date')),
                                    DataColumn(label: Text('Total Points')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: snapshot.data!.docs.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final name = data['name'] ?? 'Unknown';
                                    final email = data['email'] ?? 'No email';
                                    final joinDate = data['createdAt'] != null
                                        ? (data['createdAt'] as Timestamp)
                                            .toDate()
                                        : DateTime.now();

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              Text(name),
                                              if (data['isRestricted'] == true)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'RESTRICTED',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              if (data['dailyPointLimit'] != null)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'LIMIT: ${data['dailyPointLimit']}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(email)),
                                        DataCell(Text(_formatDate(joinDate))),
                                        DataCell(
                                            _buildTotalPointsWidget(doc.id)),
                                        DataCell(Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility,
                                                  color: Colors.blue),
                                              onPressed: () =>
                                                  _showCustomerDetails(
                                                      context, doc.id, data),
                                              tooltip: 'View Details',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _showDeleteConfirmation(
                                                      context, doc.id),
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
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
                        final email = data['email'] ?? 'No email';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: data['isRestricted'] == true 
                                ? Colors.red.withOpacity(0.2)
                                : MColors.primary.withOpacity(0.2),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: data['isRestricted'] == true 
                                    ? Colors.red
                                    : MColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(name)),
                              if (data['isRestricted'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'RESTRICTED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (data['dailyPointLimit'] != null)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'LIMIT: ${data['dailyPointLimit']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(email),
                          trailing: _buildTotalPointsChip(doc.id),
                          onTap: () =>
                              _showCustomerDetails(context, doc.id, data),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        );
      }),
      // FAB for adding customers
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCustomerDialog(context),
        backgroundColor: MColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCustomerDetails(
      BuildContext context, String customerId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'No email';

    // Determine if we're on desktop/web based on width
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final isTablet = MediaQuery.of(context).size.width > 600 &&
        MediaQuery.of(context).size.width <= 1000;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: isDesktop ? 700 : (isTablet ? 600 : null),
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 700 : (isTablet ? 600 : double.infinity),
            maxHeight: isDesktop || isTablet ? 600 : 500,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$name - Profile',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: isDesktop || isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column - Basic info
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Customer Information',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: MColors.primary),
                                        onPressed: () {
                                          Get.back();
                                          _showEditCustomerDialog(context, customerId, data);
                                        },
                                        tooltip: 'Edit Customer',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow('First Name',
                                      data['firstName'] ?? 'Not provided'),
                                  _buildDetailRow('Last Name',
                                      data['lastName'] ?? 'Not provided'),
                                  _buildDetailRow('Email', email),
                                  _buildDetailRow(
                                      'Date of Birth',
                                      data['dateOfBirth'] != null
                                          ? _formatDate(
                                              (data['dateOfBirth'] as Timestamp)
                                                  .toDate())
                                          : 'Not provided'),
                                  _buildDetailRow(
                                      'Joined Date',
                                      data['createdAt'] != null
                                          ? _formatDate(
                                              (data['createdAt'] as Timestamp)
                                                  .toDate())
                                          : 'Unknown'),
                                  _buildDetailRow(
                                      'Status',
                                      data['isRestricted'] == true
                                          ? 'Restricted'
                                          : 'Active'),
                                  if (data['isRestricted'] == true)
                                    _buildDetailRow(
                                        'Restriction Reason',
                                        data['restrictionReason'] ?? 'No reason provided'),
                                  if (data['dailyPointLimit'] != null)
                                    _buildDetailRow(
                                        'Daily Point Limit',
                                        '${data['dailyPointLimit']} points'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            // Right column - Points info
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Points By Restaurant',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPointsSection(customerId),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Customer Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: MColors.primary),
                                  onPressed: () {
                                    Get.back();
                                    _showEditCustomerDialog(context, customerId, data);
                                  },
                                  tooltip: 'Edit Customer',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('First Name',
                                data['firstName'] ?? 'Not provided'),
                            _buildDetailRow('Last Name',
                                data['lastName'] ?? 'Not provided'),
                            _buildDetailRow('Email', email),
                            _buildDetailRow(
                                'Date of Birth',
                                data['dateOfBirth'] != null
                                    ? _formatDate(
                                        (data['dateOfBirth'] as Timestamp)
                                            .toDate())
                                    : 'Not provided'),
                            _buildDetailRow(
                                'Joined Date',
                                data['createdAt'] != null
                                    ? _formatDate(
                                        (data['createdAt'] as Timestamp)
                                            .toDate())
                                    : 'Unknown'),
                            _buildDetailRow(
                                'Status',
                                data['isRestricted'] == true
                                    ? 'Restricted'
                                    : 'Active'),
                            if (data['isRestricted'] == true)
                              _buildDetailRow(
                                  'Restriction Reason',
                                  data['restrictionReason'] ?? 'No reason provided'),
                            if (data['dailyPointLimit'] != null)
                              _buildDetailRow(
                                  'Daily Point Limit',
                                  '${data['dailyPointLimit']} points'),
                            const Divider(),
                            const Text(
                              'Points By Restaurant',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPointsSection(customerId),
                          ],
                        ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - Restriction actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Management',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (data['isRestricted'] == true)
                            ElevatedButton.icon(
                              onPressed: () => _showUnrestrictDialog(context, customerId),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Unrestrict'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => _showRestrictDialog(context, customerId),
                              icon: const Icon(Icons.block, size: 16),
                              label: const Text('Restrict'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showPointLimitDialog(context, customerId, data),
                            icon: const Icon(Icons.speed, size: 16),
                            label: const Text('Point Limit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Right side - Close and Delete
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _showDeleteConfirmation(context, customerId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Delete Customer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String customerId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
          'Are you sure you want to delete this customer? This action cannot be undone.',
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
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(customerId)
                    .delete();
                Get.back();
                Get.snackbar(
                  'Success',
                  'Customer deleted successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to delete customer: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
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

  Widget _buildTotalPointsWidget(String customerId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('scans')
          .where('clientId', isEqualTo: customerId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }
        
        if (snapshot.hasError) {
          return const Text('Error');
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('0');
        }
        
        int totalPoints = 0;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalPoints += (data['pointsAwarded'] as int?) ?? 0;
        }
        
        return Text('$totalPoints');
      },
    );
  }

  Widget _buildTotalPointsChip(String customerId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('scans')
          .where('clientId', isEqualTo: customerId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Chip(
            label: Text('Loading...'),
            backgroundColor: Colors.grey,
            labelStyle: TextStyle(color: Colors.white),
          );
        }
        
        if (snapshot.hasError) {
          return const Chip(
            label: Text('Error'),
            backgroundColor: Colors.red,
            labelStyle: TextStyle(color: Colors.white),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Chip(
            label: Text('0 pts'),
            backgroundColor: Colors.blue,
            labelStyle: TextStyle(color: Colors.white),
          );
        }
        
        int totalPoints = 0;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalPoints += (data['pointsAwarded'] as int?) ?? 0;
        }
        
        return Chip(
          label: Text('$totalPoints pts'),
          backgroundColor: Colors.blue,
          labelStyle: const TextStyle(color: Colors.white),
        );
      },
    );
  }

  Widget _buildPointsSection(String customerId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('scans')
          .where('clientId', isEqualTo: customerId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error loading loyalty data: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No scan data found');
        }

        // Group scans by restaurant and calculate total points
        Map<String, int> pointsByRestaurant = {};
        int totalPoints = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final restaurantId = data['restaurantId'] as String? ?? '';
          final pointsAwarded = data['pointsAwarded'] as int? ?? 0;

          if (restaurantId.isNotEmpty) {
            pointsByRestaurant[restaurantId] =
                (pointsByRestaurant[restaurantId] ?? 0) + pointsAwarded;
            totalPoints += pointsAwarded;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: MColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Total Points: $totalPoints',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...pointsByRestaurant.entries.map((entry) {
              final restaurantId = entry.key;
              final points = entry.value;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('restaurants')
                    .doc(restaurantId)
                    .get(),
                builder: (context, restaurantSnapshot) {
                  String restaurantName = 'Unknown Restaurant';
                  if (restaurantSnapshot.hasData &&
                      restaurantSnapshot.data!.exists) {
                    final restaurantData = restaurantSnapshot.data!.data()
                        as Map<String, dynamic>?;
                    restaurantName = restaurantData?['restaurantName'] ??
                        'Unknown Restaurant';
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(restaurantName)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: MColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$points pts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _showEditCustomerDialog(BuildContext context, String customerId, Map<String, dynamic> data) {
    final TextEditingController firstNameController = TextEditingController(text: data['firstName'] ?? '');
    final TextEditingController lastNameController = TextEditingController(text: data['lastName'] ?? '');
    final Rx<DateTime?> selectedDate = Rx<DateTime?>(
      data['dateOfBirth'] != null ? (data['dateOfBirth'] as Timestamp).toDate() : null
    );
    final dateFormat = DateFormat('d MMMM, yyyy');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Customer Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              // First Name
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth
              Obx(() => InkWell(
                onTap: () => _selectDateForEdit(context, selectedDate),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate.value != null
                            ? dateFormat.format(selectedDate.value!)
                            : 'Select date of birth',
                        style: TextStyle(
                          color: selectedDate.value != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (firstNameController.text.trim().isEmpty ||
                                lastNameController.text.trim().isEmpty ||
                                selectedDate.value == null) {
                              Get.snackbar(
                                'Error',
                                'Please fill all required fields',
                                backgroundColor: Colors.red[100],
                                colorText: Colors.red[800],
                              );
                              return;
                            }

                            await controller.updateCustomerDetails(
                              customerId: customerId,
                              firstName: firstNameController.text.trim(),
                              lastName: lastNameController.text.trim(),
                              dateOfBirth: selectedDate.value!,
                            );
                            Get.back();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Update'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCustomerDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final RxBool isPasswordVisible = false.obs;
    final RxBool isConfirmPasswordVisible = false.obs;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create New Customer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              Form(
                key: formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        if (!GetUtils.isEmail(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Obx(() => TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => isPasswordVisible.value = !isPasswordVisible.value,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: !isPasswordVisible.value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    )),
                    const SizedBox(height: 16),

                    // Confirm Password
                    Obx(() => TextFormField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: !isConfirmPasswordVisible.value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    )),
                    const SizedBox(height: 24),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Customer will receive an email verification link and must complete their profile information.',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        Obx(() => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () async {
                                  if (formKey.currentState?.validate() ?? false) {
                                    await controller.createCustomerAccount(
                                      email: emailController.text.trim(),
                                      password: passwordController.text,
                                    );
                                    Get.back();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Customer'),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateForEdit(BuildContext context, Rx<DateTime?> selectedDate) async {
    final DateTime now = DateTime.now();
    final DateTime minDate = DateTime(1925, 1, 1);
    final DateTime maxDate = DateTime(2025, 12, 31);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: MColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: MColors.primary),
                      ),
                    ),
                    Text(
                      'Select Date of Birth',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: MColors.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(color: MColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate.value ?? DateTime(1990),
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  onDateTimeChanged: (DateTime value) {
                    selectedDate.value = value;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRestrictDialog(BuildContext context, String customerId) {
    final TextEditingController reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Restrict Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to restrict this customer?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for restriction (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Violation of terms, suspicious activity',
              ),
              maxLines: 2,
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
              await controller.restrictCustomer(
                customerId,
                reason: reasonController.text.trim().isEmpty 
                    ? null 
                    : reasonController.text.trim(),
              );
              Get.back();
              Get.back(); // Close customer details dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restrict'),
          ),
        ],
      ),
    );
  }

  void _showUnrestrictDialog(BuildContext context, String customerId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Restriction'),
        content: const Text('Are you sure you want to remove the restriction from this customer?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.unrestrictCustomer(customerId);
              Get.back();
              Get.back(); // Close customer details dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unrestrict'),
          ),
        ],
      ),
    );
  }

  void _showPointLimitDialog(BuildContext context, String customerId, Map<String, dynamic> data) {
    final TextEditingController limitController = TextEditingController(
      text: data['dailyPointLimit']?.toString() ?? '',
    );
    final currentLimit = data['dailyPointLimit'] as int?;

    Get.dialog(
      AlertDialog(
        title: const Text('Set Daily Point Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentLimit != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current limit: $currentLimit points per day',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            if (currentLimit != null) const SizedBox(height: 16),
            TextField(
              controller: limitController,
              decoration: const InputDecoration(
                labelText: 'Daily point limit',
                border: OutlineInputBorder(),
                hintText: 'e.g., 5',
                suffixText: 'points',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'Set to 0 or leave empty to remove limit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          if (currentLimit != null)
            ElevatedButton(
              onPressed: () async {
                await controller.removeCustomerPointLimit(customerId);
                Get.back();
                Get.back(); // Close customer details dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove Limit'),
            ),
          ElevatedButton(
            onPressed: () async {
              final limitText = limitController.text.trim();
              if (limitText.isEmpty) {
                await controller.removeCustomerPointLimit(customerId);
              } else {
                final limit = int.tryParse(limitText);
                if (limit != null && limit >= 0) {
                  await controller.setCustomerPointLimit(customerId, limit);
                } else {
                  Get.snackbar(
                    'Error',
                    'Please enter a valid number (0 or greater)',
                    backgroundColor: Colors.red[100],
                    colorText: Colors.red[800],
                  );
                  return;
                }
              }
              Get.back();
              Get.back(); // Close customer details dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(currentLimit != null ? 'Update Limit' : 'Set Limit'),
          ),
        ],
      ),
    );
  }
} 