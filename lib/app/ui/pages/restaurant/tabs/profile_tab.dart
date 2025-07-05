import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart';
import 'package:rizq/app/controllers/auth_controller.dart';
import 'package:rizq/app/controllers/admin_controller.dart';
import 'package:rizq/app/routes/app_pages.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rizq/app/ui/theme/widget_themes/cached_image_widget.dart';
import 'package:rizq/app/ui/theme/widget_themes/shimmer_widget.dart';
import 'package:rizq/app/ui/widgets/language_selector.dart';
import 'package:rizq/app/utils/contact_us_helper.dart';
import 'package:rizq/app/utils/account_deletion_helper.dart';
import 'package:intl/intl.dart';

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
                } else if (value == 'delete_account') {
                  AccountDeletionHelper.confirmAccountDeletion(context, authController);
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
                  value: 'delete_account',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever,
                          color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text('Account Deletion'),
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
                  _buildProfessionalReadOnlyField('Restaurant Name', profile.name),
                        _buildProfessionalReadOnlyField('Owner Name', profile.ownerName ?? 'Not provided'),
                  const SizedBox(height: 25),

                  // Restaurant Registration Information (Read-only)
                  // _buildLabelWithDivider('Registration Information'),
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.grey[50],
                  //     borderRadius: BorderRadius.circular(8),
                  //     border: Border.all(color: Colors.grey[300]!),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       const Text(
                  //         'Restaurant Details',
                  //         style: TextStyle(
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 12),
                  //       _buildProfessionalReadOnlyField('Restaurant Name', profile.name),
                  //       _buildProfessionalReadOnlyField('Owner Name', profile.ownerName ?? 'Not provided'),
                  //       // Support Email field removed as per requirements
                  //       // Banking Options - Hidden for now but kept for future use
                  //       // if (profile.bankDetails != null && profile.bankDetails!.isNotEmpty)
                  //       //   _buildReadOnlyField('Bank Details', profile.bankDetails!),
                  //       // if (profile.ibanNumber != null && profile.ibanNumber!.isNotEmpty)
                  //       //   _buildReadOnlyField('IBAN Number', profile.ibanNumber!),
                  //       const SizedBox(height: 16),

                  //       // National ID Images
                  //       if (profile.ownerNationalIdFront != null ||
                  //           profile.ownerNationalIdBack != null) ...[
                  //         const Text(
                  //           'National ID Documents',
                  //           style: TextStyle(
                  //             fontSize: 14,
                  //             fontWeight: FontWeight.w500,
                  //           ),
                  //         ),
                  //         const SizedBox(height: 8),
                  //         Row(
                  //           children: [
                  //             if (profile.ownerNationalIdFront != null)
                  //               Expanded(
                  //                 child: Column(
                  //                   children: [
                  //                     const Text('Front Side',
                  //                         style: TextStyle(fontSize: 12)),
                  //                     const SizedBox(height: 4),
                  //                     ClipRRect(
                  //                       borderRadius: BorderRadius.circular(4),
                  //                       child: CachedImageWidget(
                  //                         imageUrl:
                  //                             profile.ownerNationalIdFront!,
                  //                         width: double.infinity,
                  //                         height: 60,
                  //                         fit: BoxFit.cover,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             if (profile.ownerNationalIdFront != null &&
                  //                 profile.ownerNationalIdBack != null)
                  //               const SizedBox(width: 8),
                  //             if (profile.ownerNationalIdBack != null)
                  //               Expanded(
                  //                 child: Column(
                  //                   children: [
                  //                     const Text('Back Side',
                  //                         style: TextStyle(fontSize: 12)),
                  //                     const SizedBox(height: 4),
                  //                     ClipRRect(
                  //                       borderRadius: BorderRadius.circular(4),
                  //                       child: CachedImageWidget(
                  //                         imageUrl:
                  //                             profile.ownerNationalIdBack!,
                  //                         width: double.infinity,
                  //                         height: 60,
                  //                         fit: BoxFit.cover,
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //           ],
                  //         ),
                  //       ],
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 25),
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
                        Builder(
                          builder: (context) {
                            // Get the subscription plan name dynamically
                            String planName = 'Starter Tier'; // Fallback
                            String expiryText = '';
                            
                            if (profile.subscriptionStatus == 'free_trial') {
                              planName = 'Free Trial';
                              expiryText = '${profile.remainingTrialDays} days remaining';
                            } else {
                              // Try to get readable name from admin controller
                              String fallbackName = profile.subscriptionPlan.capitalizeFirst ?? profile.subscriptionPlan;
                              try {
                                final adminController = Get.find<AdminController>();
                                final plan = adminController.subscriptionPlans.firstWhere(
                                  (p) => p.id == profile.subscriptionPlan
                                );
                                fallbackName = plan.name;
                              } catch (_) {
                                // Keep fallbackName if plan not found
                              }
                              planName = fallbackName;
                              
                              // Set expiry text for active subscriptions
                              if (profile.subscriptionEnd != null) {
                                expiryText = 'Expires on ${DateFormat('MMM d, yyyy').format(profile.subscriptionEnd!)}';
                              }
                            }
                            
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Expiry date on the left
                                if (expiryText.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      expiryText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                // Plan name on the right
                                Text(
                                  planName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          },
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

                  const SizedBox(height: 25),                  

                  // Logout button
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => authController.logout(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.red,
                          ),
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

  // All contact us and account deletion functionality moved to helper classes

  // Method to update bank details
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

  Widget _buildProfessionalReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey[100],
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
