import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart';
import 'package:rizq/app/controllers/auth_controller.dart';
import 'package:rizq/app/routes/app_pages.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rizq/app/ui/theme/widget_themes/cached_image_widget.dart';
import 'package:rizq/app/ui/theme/widget_themes/shimmer_widget.dart';
import 'package:rizq/app/ui/widgets/language_selector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final bankDetailsController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    bankDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RestaurantController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: Obx(() {
        if (controller.isLoadingProfile.value) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile image shimmer
                ShimmerWidget.circular(
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 30),

                // Restaurant name field shimmer
                ShimmerWidget.rounded(height: 50),
                const SizedBox(height: 20),

                // Address field shimmer
                ShimmerWidget.rounded(height: 50),
                const SizedBox(height: 25),

                // Logo field shimmer
                ShimmerWidget.rounded(height: 48),
                const SizedBox(height: 25),

                // Subscription section shimmer
                ShimmerWidget.rounded(height: 120),
              ],
            ),
          );
        }

        final profile = controller.restaurantProfile.value;
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Please complete your profile setup'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.toNamed(Routes.RESTAURANT_PROFILE_SETUP),
                  child: const Text('Setup Profile'),
                ),
              ],
            ),
          );
        }

        // Initialize text controllers with current values
        nameController.text = profile.name;
        emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
        bankDetailsController.text = controller.bankDetails;

        // Profile content
        return Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // RIZQ Logo at top
                  profile.logoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: CachedImageWidget(
                            imageUrl: profile.logoUrl,
                            width: 100,
                            height: 100,
                            borderRadius: BorderRadius.circular(100),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.grey[200],
                          ),
                          child: Icon(Icons.image,
                              color: Colors.grey[400], size: 40),
                        ),

                  const SizedBox(height: 30),

                  // Restaurant name field (editable)
                  _buildEditableField(
                    context,
                    'Restaurant Name',
                    nameController,
                    isRequired: true,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Restaurant name is required'
                        : null,
                  ),

                  // Email field (Non Edidable)
                  _buildEditableField(
                    context,
                    'Email',
                    emailController,
                    isRequired: true,
                    readOnly: true,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Email is required' : null,
                  ),

                  // Logo field
                  _buildLabelWithDivider('Logo'),
                  InkWell(
                    onTap: () {
                      controller.pickAndUploadLogo();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: profile.logoUrl.isNotEmpty
                                ? CachedImageWidget(
                                    imageUrl: profile.logoUrl,
                                    width: 24,
                                    height: 24,
                                    borderRadius: BorderRadius.circular(2),
                                    fit: BoxFit.cover,
                                  )
                                : Icon(Icons.image,
                                    color: Colors.grey[400], size: 16),
                          ),
                          const SizedBox(width: 10),
                          Obx(() => controller.isLoadingUpload.value
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: MColors.primary,
                                  ),
                                )
                              : Text(
                                  'Change logo',
                                  style: TextStyle(
                                    color: MColors.primary,
                                    fontSize: 14,
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Subscription section
                  _buildLabelWithDivider('Subscription'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: MColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: MColors.primary),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: MColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${controller.scanCount} scans this month',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Starter Tier',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () =>
                                Get.toNamed(Routes.RESTAURANT_SUBSCRIPTION),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(color: MColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Change subscription',
                              style: TextStyle(
                                color: MColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Payment failure notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payment failure. Please update your payment information (N.B it will integrated after CMI intregation)',
                            style:
                                TextStyle(color: Colors.red[700], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Banking details (editable)
                  _buildLabelWithDivider('Banking Details'),
                  _buildEditableField(
                    context,
                    null,
                    bankDetailsController,
                    hint: 'Enter your bank IBAN number',
                  ),

                  const SizedBox(height: 10),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          // Save all changes
                          controller.updateRestaurantDetails(
                            nameController.text,
                            emailController.text,
                          );

                          // Update bank details
                          _updateBankDetails(
                              controller, bankDetailsController.text);
                        }
                      },
                      child: Obx(() => controller.isLoadingProfile.value
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            )),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logout and delete account row
                  Column(
                    children: [
                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => authController.logout(),
                          child: Text(
                            'logout'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // Show Contact Us dialog
  void _showContactUsDialog(BuildContext context) {
    final supportEmail = 'support@rizq.app';
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Us'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have a question regarding the Rizq application?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: MColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        supportEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: MColors.primary),
                      onPressed: () {
                        _copyToClipboard(supportEmail);
                      },
                      tooltip: 'Copy to clipboard',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subject field
              Text(
                'Subject',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  hintText: 'Enter subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe your issue or question',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _launchEmailApp(
                supportEmail,
                subjectController.text,
                descriptionController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Launch email app with pre-filled information
  void _launchEmailApp(String email, String subject, String body) async {
    final controller = Get.find<RestaurantController>();
    final profile = controller.restaurantProfile.value;
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Create email body with footer
    final completeBody = '''
$body

Regards,
${profile?.name ?? 'Restaurant'}
$userEmail
Restaurant UID: $uid
''';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters({
        'subject': subject,
        'body': completeBody,
      }),
    );

    try {
      // Try to launch with explicit app selection
      final bool launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      );

      if (launched) {
        Navigator.of(Get.context!).pop(); // Close the dialog after launching
      } else {
        // Fallback: Show a dialog with the email information that can be copied
        _showEmailCopyDialog(email, subject, completeBody);
      }
    } catch (e) {
      // Show error and manual email instructions
      _showEmailCopyDialog(email, subject, completeBody);
    }
  }

  // Show dialog with email information that can be copied
  void _showEmailCopyDialog(String email, String subject, String body) {
    Get.dialog(
      AlertDialog(
        title: const Text('Email Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not launch email app automatically. Please copy the information below and send an email manually:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildCopyableField('Email', email),
              const SizedBox(height: 8),
              _buildCopyableField('Subject', subject),
              const SizedBox(height: 8),
              _buildCopyableField('Message', body, maxLines: 5),
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

  // Build a copyable text field with a copy button
  Widget _buildCopyableField(String label, String content, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SelectableText(
                    content,
                    maxLines: maxLines,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: MColors.primary),
                onPressed: () {
                  _copyToClipboard(content);
                },
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Copy text to clipboard and show a snackbar
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      'Text copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // Helper method to encode query parameters
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // Show Delete Account Confirmation dialog
  void _showDeleteAccountConfirmation(
      BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmAccountDeletion(context, authController);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
            ),
            child: const Text('Yes, I want to delete my account'),
          ),
        ],
      ),
    );
  }

  // Final confirmation for account deletion
  void _confirmAccountDeletion(
      BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: const Text(
            'This action is permanent and cannot be undone. All your data will be deleted. Do you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Execute the account deletion
              // TODO: Implement account deletion in AuthController
              // authController.deleteAccount();
              Get.snackbar(
                'Account Deletion',
                'Your account deletion request has been submitted.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red[700],
                colorText: Colors.white,
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // Method to update bank details
  void _updateBankDetails(RestaurantController controller, String bankDetails) {
    if (bankDetails.isEmpty) return;

    // Use controller method to update bank details
    controller.updateBankDetails(bankDetails);
  }

  Widget _buildEditableField(
    BuildContext context,
    String? label,
    TextEditingController controller, {
    String? hint,
    bool isRequired = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.red[700],
                  ),
                ),
            ],
          ),
        if (label != null) const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(5),
            color: readOnly ? Colors.grey[100] : Colors.white,
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: hint ?? 'Enter ${label?.toLowerCase() ?? ''}',
              border: const OutlineInputBorder().copyWith(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(width: 1, color: MColors.grey),
              ),
              enabledBorder: const OutlineInputBorder().copyWith(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(width: 1, color: MColors.grey),
              ),
              focusedBorder: const OutlineInputBorder().copyWith(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(width: 1, color: MColors.dark),
              ),
              errorBorder: const OutlineInputBorder().copyWith(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(width: 1, color: MColors.warning),
              ),
              focusedErrorBorder: const OutlineInputBorder().copyWith(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(width: 2, color: MColors.warning),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            style: const TextStyle(
              fontSize: 14,
            ),
            validator: validator,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLabelWithDivider(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
