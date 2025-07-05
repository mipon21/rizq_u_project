import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../controllers/admin_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../ui/theme/widget_themes/cached_image_widget.dart';

class RestaurantRegistrationsPage extends GetView<AdminController> {
  const RestaurantRegistrationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Registrations'),
        backgroundColor: MColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurant_registrations')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allRegistrations = snapshot.data?.docs ?? [];
          
          // Filter to only show pending registrations
          final registrations = allRegistrations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final approvalStatus = data['approvalStatus'] ?? 'pending';
            return approvalStatus == 'pending';
          }).toList();

          // Debug logging
          print('📋 Restaurant Registrations Page:');
          print('   - Total registrations: ${allRegistrations.length}');
          print('   - Pending registrations: ${registrations.length}');
          final statusCounts = <String, int>{};
          for (var doc in allRegistrations) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['approvalStatus'] ?? 'pending';
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }
          statusCounts.forEach((status, count) {
            print('   - $status: $count');
          });

          if (registrations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No pending restaurant registrations',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All registrations have been processed',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              final doc = registrations[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _buildRegistrationCard(context, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildRegistrationCard(BuildContext context, String registrationId, Map<String, dynamic> data) {
    final restaurantName = data['restaurantName'] ?? 'No restaurant name';
    final ownerName = data['ownerName'] ?? 'No owner name';
    final email = data['email'] ?? 'No email';
    final supportEmail = data['supportEmail'] ?? 'No support email';
    final approvalStatus = data['approvalStatus'] ?? 'pending';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final logoUrl = data['logoUrl'] ?? '';
    final bankDetails = data['bankDetails'] ?? '';
    final ibanNumber = data['ibanNumber'] ?? '';
    final nationalIdFront = data['ownerNationalIdFront'] ?? '';
    final nationalIdBack = data['ownerNationalIdBack'] ?? '';

    Color statusColor;
    String statusText;
    switch (approvalStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Restaurant Logo
                if (logoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedImageWidget(
                      imageUrl: logoUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: $ownerName',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Contact Information
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Email', email),
            if (supportEmail != null &&
                supportEmail != 'No support email' &&
                supportEmail.isNotEmpty)
              _buildDetailRow('Support Email', supportEmail),
            
            // Bank Information
            const SizedBox(height: 12),
            const Text(
              'Bank Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (bankDetails != null && bankDetails.isNotEmpty)
              _buildDetailRow('Bank Details', bankDetails),
            if (ibanNumber != null && ibanNumber.isNotEmpty)
              _buildDetailRow('IBAN Number', ibanNumber),
            
            // National ID Images
            if (nationalIdFront.isNotEmpty || nationalIdBack.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'National ID Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (nationalIdFront.isNotEmpty)
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Front Side'),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedImageWidget(
                              imageUrl: nationalIdFront,
                              width: double.infinity,
                              height: 80,
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
                          const Text('Back Side'),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedImageWidget(
                              imageUrl: nationalIdBack,
                              width: double.infinity,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            
            // Action Buttons
            if (approvalStatus == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.approveRestaurant(registrationId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRejectDialog(context, registrationId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
            
            if (approvalStatus == 'rejected') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['rejectionReason'] ?? 'No reason provided',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
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

  void _showRejectDialog(BuildContext context, String registrationId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
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
              controller.rejectRestaurant(registrationId, reasonController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
} 