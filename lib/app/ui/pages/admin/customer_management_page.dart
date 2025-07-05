import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/colors.dart';
import '../../../controllers/admin_controller.dart';

class CustomerManagementPage extends GetView<AdminController> {
  const CustomerManagementPage({Key? key}) : super(key: key);

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
                                  headingRowColor: MaterialStateProperty.all(
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
                                        DataCell(Text(name)),
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
                            backgroundColor: MColors.primary.withOpacity(0.2),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: MColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(name),
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
      // FAB for adding customers (optional)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement add customer functionality
        },
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
                                  const Text(
                                    'Customer Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
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
                mainAxisAlignment: MainAxisAlignment.end,
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
            }).toList(),
          ],
        );
      },
    );
  }
}
