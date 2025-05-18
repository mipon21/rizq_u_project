import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/customer_controller.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerProfilePage extends GetView<CustomerController> {
  const CustomerProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

    // Date formatter
    final dateFormat = DateFormat('d MMMM, yyyy');

    // Initialize form controllers with current profile data
    void initFormValues() {
      final profile = controller.customerProfile.value;
      if (profile != null) {
        nameController.text = profile.name;
        phoneController.text = profile.phoneNumber ?? '';
        selectedDate.value = profile.dateOfBirth;
      }
    }

    // Helper method to encode query parameters
    String _encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    // Helper to launch email
    Future<void> _launchEmail(String email, String subject) async {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: email,
        query: _encodeQueryParameters({
          'subject': subject,
        }),
      );

      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        Get.snackbar(
          'Error',
          'Could not launch email client',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    // Date picker function
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != selectedDate.value) {
        selectedDate.value = picked;
      }
    }

    // Final confirmation for account deletion
    void _confirmDeleteAccount() {
      AuthController authController = Get.find<AuthController>();
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
                // Execute account deletion
                authController.deleteAccount();
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

    // Show account deletion confirmation dialog
    void _showDeleteAccountConfirmation() {
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
                _confirmDeleteAccount();
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

    // Show loyalty programs question dialog
    void _showLoyaltyProgramsQuestion() async {
      // Get the user's active loyalty programs
      if (controller.loyaltyCards.isEmpty) {
        await controller.fetchLoyaltyData();
      }

      if (controller.loyaltyCards.isEmpty) {
        Get.snackbar(
          'No Loyalty Programs',
          'You don\'t have any active loyalty programs',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Loyalty Program'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: controller.loyaltyCards.length,
              itemBuilder: (context, index) {
                final program = controller.loyaltyCards[index];
                return ListTile(
                  leading: program.logoUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(program.logoUrl),
                        )
                      : CircleAvatar(
                          child: Text(program.restaurantName[0]),
                        ),
                  title: Text(program.restaurantName),
                  subtitle: Text(
                      '${program.points}/${program.pointsRequired} points'),
                  onTap: () async {
                    Navigator.of(context).pop();

                    // Get restaurant's email from Firestore
                    try {
                      DocumentSnapshot restaurantDoc = await FirebaseFirestore
                          .instance
                          .collection('restaurants')
                          .doc(program.restaurantId)
                          .get();

                      if (restaurantDoc.exists) {
                        String email =
                            restaurantDoc.get('email') ?? 'support@rizq.com';
                        _launchEmail(email,
                            'Question about loyalty program at ${program.restaurantName}');
                      } else {
                        _launchEmail('support@rizq.com',
                            'Question about loyalty program at ${program.restaurantName}');
                      }
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'Could not fetch restaurant contact information',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      _launchEmail('support@rizq.com',
                          'Question about loyalty program at ${program.restaurantName}');
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    // Show Rizq application question dialog
    void _showRizqAppQuestion() {
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (context) => Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: MColors.primary.withOpacity(0.5),
          ),
          child: AlertDialog(
            backgroundColor: MColors.primary.withOpacity(0.5),
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Contact Rizq Support',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'For questions regarding the Rizq app, please contact our support team:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'support@rizq.com',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon:
                          const Icon(Icons.copy, size: 18, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(
                            const ClipboardData(text: 'support@rizq.com'));
                        Get.snackbar(
                          'Copied',
                          'Email address copied to clipboard',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _launchEmail(
                      'support@rizq.com', 'Question about Rizq Application');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: MColors.primary,
                ),
                child: const Text('Send Email'),
              ),
            ],
          ),
        ),
      );
    }

    // Show help options dialog
    void _showContactUsOptions() {
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (context) => Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
          ),
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Contact Us',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.card_giftcard,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Question about loyalty program'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showLoyaltyProgramsQuestion();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.app_settings_alt,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('Question about Rizq application'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showRizqAppQuestion();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    AuthController authController = Get.find<AuthController>();
    return Scaffold(
      body: Obx(() {
        final profile = controller.customerProfile.value;

        // Show shimmer while loading OR if profile is null (indicating we should try loading again)
        if (controller.isLoadingProfile.value || profile == null) {
          // If profile is null and not loading, trigger a fetch
          if (!controller.isLoadingProfile.value && profile == null) {
            controller.fetchCustomerProfile();
          }
          return _buildProfileLoadingShimmer(context);
        }

        // Initialize form with current values
        initFormValues();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          child: profile!.photoUrl != null &&
                                  profile.photoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: CachedNetworkImage(
                                    imageUrl: profile.photoUrl!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: controller.isUploadingImage.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                              onPressed: controller.isUploadingImage.value
                                  ? null
                                  : () => controller.uploadProfileImage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Fields
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Read-only email field
                  TextFormField(
                    initialValue: profile.email,
                    readOnly: true,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email (Cannot be changed)',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth field with date picker
                  Obx(() => InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedDate.value != null
                                    ? dateFormat.format(selectedDate.value!)
                                    : 'Select your date of birth',
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
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isUpdatingProfile.value
                          ? null
                          : () {
                              if (formKey.currentState?.validate() ?? false) {
                                controller.updateProfile(
                                  name: nameController.text,
                                  phoneNumber: phoneController.text,
                                  dateOfBirth: selectedDate.value,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: controller.isUpdatingProfile.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SAVE CHANGES',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Member since: ${DateFormat('MMMM d, yyyy').format(profile.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'User ID: ${profile.uid}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        authController.logout();
                      },
                      // style: ElevatedButton.styleFrom(
                      //   backgroundColor: Colors.red,
                      //   foregroundColor: Colors.white,
                      // ),
                      child: const Text('LOGOUT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // Profile loading shimmer
  Widget _buildProfileLoadingShimmer(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image Shimmer
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Form fields shimmer
              Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 32),

              // Button shimmer
              Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
