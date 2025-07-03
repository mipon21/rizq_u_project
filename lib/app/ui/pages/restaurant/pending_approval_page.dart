import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/restaurant_registration_controller.dart';
import '../../../models/restaurant_registration_model.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/support_constants.dart';
import '../../../ui/theme/widget_themes/cached_image_widget.dart';
import '../../../routes/app_pages.dart';

class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({Key? key}) : super(key: key);

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage> {
  final RestaurantRegistrationController controller = Get.find<RestaurantRegistrationController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadRegistrationData();
  }

  Future<void> _loadRegistrationData() async {
    await controller.fetchRegistrationData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Status'),
        backgroundColor: MColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
      body: Obx(() {
        final registration = controller.registrationData.value;
        
        if (registration == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(registration),
              const SizedBox(height: 24),
              _buildRegistrationDetails(registration),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusCard(RestaurantRegistrationModel registration) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusMessage;

    switch (registration.approvalStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Under Review';
        statusMessage = 'Your restaurant registration is currently under review by our admin team. This process typically takes 1-3 business days.';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        statusMessage = 'Congratulations! Your restaurant has been approved. You can now access your dashboard.';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        statusMessage = registration.rejectionReason ?? SupportConstants.registrationRejectedMessage;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
        statusMessage = 'Unknown status. ${SupportConstants.genericSupportMessage}.';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              statusIcon,
              size: 64,
              color: statusColor,
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (registration.approvalStatus == 'pending') ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Review in progress...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationDetails(RestaurantRegistrationModel registration) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registration Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Restaurant Logo
            if (registration.logoUrl.isNotEmpty) ...[
              const Text(
                'Restaurant Logo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImageWidget(
                    imageUrl: registration.logoUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Basic Information
            _buildDetailRow('Restaurant Name', registration.restaurantName),
            _buildDetailRow('Owner Name', registration.ownerName),
            _buildDetailRow('Email', registration.email),
            _buildDetailRow('Support Email', registration.supportEmail),
            _buildDetailRow('Bank Details', registration.bankDetails),
            _buildDetailRow('IBAN Number', registration.ibanNumber),
            
            // National ID Images
            if (registration.ownerNationalIdFront.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Front Side'),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedImageWidget(
                            imageUrl: registration.ownerNationalIdFront,
                            width: double.infinity,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Back Side'),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedImageWidget(
                            imageUrl: registration.ownerNationalIdBack,
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

            const SizedBox(height: 16),
            _buildDetailRow('Submitted On', _formatDate(registration.createdAt)),
            if (registration.approvedAt != null)
              _buildDetailRow('Approved On', _formatDate(registration.approvedAt!)),
            if (registration.rejectedAt != null)
              _buildDetailRow('Rejected On', _formatDate(registration.rejectedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final registration = controller.registrationData.value;
    if (registration == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (registration.approvalStatus == 'approved')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.offAllNamed(Routes.RESTAURANT_DASHBOARD);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Go to Dashboard',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        
        if (registration.approvalStatus == 'rejected')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showContactSupportDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Contact Support',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        
        if (registration.approvalStatus == 'pending')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _showContactSupportDialog();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Contact Support',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'If you have any questions about your registration status, please contact our support team:\n\n'
                      'Email: ${SupportConstants.supportEmail}\n\n'
          'We\'re here to help!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 