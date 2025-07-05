import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rizq/app/controllers/auth_controller.dart';
import 'package:rizq/app/utils/contact_us_helper.dart';
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
  final RestaurantRegistrationController controller =
      Get.find<RestaurantRegistrationController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final authController = Get.find<AuthController>();

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
        title: Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              color: Colors.white,
              onSelected: (value) {
                if (value == 'contact_us') {
                  ContactUsHelper.showContactUsDialog(context);
                } else if (value == 'log_out') {
                  authController.logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'contact_us',
                  child: Row(
                    children: [
                      Icon(Icons.headset_mic_sharp,
                          color: MColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Contact Us'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'log_out',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text('Log Out'),
                    ],
                  ),
                ),
              ],
              child: Row(
                children: [
                  Icon(Icons.help,
                      color: Theme.of(context).primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Help',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              tooltip: 'Help',
            ),
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
              const SizedBox(height: 16),
              _buildRegistrationDetails(registration),
              const SizedBox(height: 16),
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
        statusMessage =
            'Thank you for your subscription! Your registration is currently under review by our admin team. This process typically takes 1-3 business days.';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        statusMessage =
            'Congratulations! Your restaurant has been approved. You can now access your dashboard.';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        statusMessage = registration.rejectionReason ??
            SupportConstants.registrationRejectedMessage;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
        statusMessage =
            'Unknown status. ${SupportConstants.genericSupportMessage}.';
    }

    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300),
        ),
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
                  color: Colors.black,
                ),
              ),
              if (registration.approvalStatus == 'rejected') ...[
                Text(
                  "[If you think this is a mistake, please contact us from the Help section]",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
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
      ),
    );
  }

  Widget _buildRegistrationDetails(RestaurantRegistrationModel registration) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 1,
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
            if (registration.supportEmail != null &&
                registration.supportEmail!.isNotEmpty)
              _buildDetailRow('Support Email', registration.supportEmail!),
            if (registration.bankDetails != null &&
                registration.bankDetails!.isNotEmpty)
              _buildDetailRow('Bank Details', registration.bankDetails!),
            if (registration.ibanNumber != null &&
                registration.ibanNumber!.isNotEmpty)
              _buildDetailRow('IBAN Number', registration.ibanNumber!),

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
            _buildDetailRow(
                'Submitted On', _formatDate(registration.createdAt)),
            if (registration.approvedAt != null)
              _buildDetailRow(
                  'Approved On', _formatDate(registration.approvedAt!)),
            if (registration.rejectedAt != null)
              _buildDetailRow(
                  'Rejected On', _formatDate(registration.rejectedAt!)),
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
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
