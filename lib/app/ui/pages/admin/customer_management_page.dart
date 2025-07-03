import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import '../../../controllers/admin_controller.dart';

class CustomerManagementPage extends GetView<AdminController> {
  const CustomerManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: MColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Customers',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter',
                  onSelected: (String value) {
                    // Handle filter selection
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'all',
                      child: Text('All Customers'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'recent',
                      child: Text('Recently Joined'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'active',
                      child: Text('Active Users'),
                    ),
                  ],
                ),
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
                              DataColumn(label: Text('Joined Date')),
                              DataColumn(label: Text('Total Points')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Unknown';
                              final email = data['email'] ?? 'No email';
                              final joinDate = data['createdAt'] != null
                                  ? (data['createdAt'] as Timestamp).toDate()
                                  : DateTime.now();

                              return DataRow(
                                cells: [
                                  DataCell(Text(name)),
                                  DataCell(Text(email)),
                                  DataCell(Text(_formatDate(joinDate))),
                                  DataCell(_buildTotalPointsWidget(doc.id)),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility,
                                            color: Colors.blue),
                                        onPressed: () => _showCustomerDetails(
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
                              child: Text(name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?'),
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
                );
              },
            ),
          ),
        ],
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

    Get.dialog(
      AlertDialog(
        title: Text('$name - Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('First Name', data['firstName'] ?? 'Not provided'),
              _buildDetailRow('Last Name', data['lastName'] ?? 'Not provided'),
              _buildDetailRow('Email', email),
              _buildDetailRow('Date of Birth', 
                  data['dateOfBirth'] != null
                      ? _formatDate((data['dateOfBirth'] as Timestamp).toDate())
                      : 'Not provided'),
              _buildDetailRow(
                  'Joined Date',
                  data['createdAt'] != null
                      ? _formatDate((data['createdAt'] as Timestamp).toDate())
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
              FutureBuilder<QuerySnapshot>(
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
                      _buildDetailRow('Total Points', '$totalPoints'),
                      const SizedBox(height: 8),
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
                            if (restaurantSnapshot.hasData && restaurantSnapshot.data!.exists) {
                              final restaurantData =
                                  restaurantSnapshot.data!.data() as Map<String, dynamic>?;
                              restaurantName =
                                  restaurantData?['restaurantName'] ?? 'Unknown Restaurant';
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(restaurantName)),
                                  Text(
                                    '$points pts',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ],
                  );
                },
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
}
