import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/colors.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/customer_controller.dart';
import 'package:intl/intl.dart';
import '../../widgets/customer/loading_shimmer.dart';

class CustomerProfilePage extends GetView<CustomerController> {
  const CustomerProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

    // Date formatter
    final dateFormat = DateFormat('d MMMM, yyyy');

    // Initialize form controllers with current profile data
    void initFormValues() {
      final profile = controller.customerProfile.value;
      if (profile != null) {
        // Split the full name into first and last name
        final nameParts = profile.name.split(' ');
        firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
        lastNameController.text =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        selectedDate.value = profile.dateOfBirth;
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
          return LoadingShimmer.buildProfileShimmer();
        }

        // Initialize form with current values
        initFormValues();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                  // Profile Fields (Read-only as per requirement)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: firstNameController,
                          readOnly: true,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            labelStyle: TextStyle(fontSize: 12),
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: lastNameController,
                          readOnly: true,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            labelStyle: TextStyle(fontSize: 12),
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                          ),
                        ),
                      ),
                    ],
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

                  // Phone number removed as per requirement

                  // Date of Birth field (Read-only)
                  TextFormField(
                    initialValue: selectedDate.value != null
                        ? dateFormat.format(selectedDate.value!)
                        : 'Not set',
                    readOnly: true,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      labelStyle: TextStyle(fontSize: 12),
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Info message instead of save button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This information was provided during registration and cannot be changed.',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account information
                  // Container(
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.grey[100],
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       const Text(
                  //         'Account Information',
                  //         style: TextStyle(
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       Text(
                  //         'Member since: ${DateFormat('MMMM d, yyyy').format(profile.createdAt)}',
                  //         style: TextStyle(
                  //           color: Colors.grey[700],
                  //         ),
                  //       ),
                  //       const SizedBox(height: 4),
                  //       Text(
                  //         'User ID: ${profile.uid}',
                  //         style: TextStyle(
                  //           color: Colors.grey[700],
                  //           fontSize: 12,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Logout button - with 10px margin from bottom
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      authController.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      }),
    );
  }


}
