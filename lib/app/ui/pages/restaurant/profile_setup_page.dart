import 'dart:io'; // Required for File type
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart'; // Adjust import

class ProfileSetupPage extends StatefulWidget {
  // Use StatefulWidget to manage TextEditControllers with initial values
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final RestaurantController controller = Get.find(); // Get controller instance
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current data from the RestaurantController
    nameController = TextEditingController(text: controller.name);
    addressController = TextEditingController(text: controller.address);

    // Listen to controller changes to update text fields if profile is fetched later
    ever(controller.restaurantProfile, (_) {
      if (mounted && controller.restaurantProfile.value != null) {
        nameController.text = controller.name;
        addressController.text = controller.address;
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Profile')),
      body: Obx(() {
        // Show loading indicator while profile is being loaded initially or during save/upload
        if (controller.isLoadingProfile.value ||
            controller.isLoadingUpload.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Setup or Update Your Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 30),

                // Logo Display and Upload Button
                Stack(
                  // Use Stack to overlay edit icon
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          controller.logoUrl.isNotEmpty
                              ? NetworkImage(controller.logoUrl)
                              : null, // Use NetworkImage if URL exists
                      child:
                          controller.logoUrl.isEmpty
                              ? const Icon(
                                Icons.storefront,
                                size: 60,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    Material(
                      // Small circle for edit button
                      color: Theme.of(context).colorScheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => controller.pickAndUploadLogo(),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => controller.pickAndUploadLogo(),
                  child: const Text('Upload Logo'),
                ),
                const SizedBox(height: 30),

                // Form Fields
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your restaurant name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2, // Allow multi-line address
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your restaurant address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Save Button
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      controller.updateRestaurantDetails(
                        nameController.text.trim(),
                        addressController.text.trim(),
                      );
                      Get.back(); // Go back after saving (optional)
                    }
                  },
                  child: const Text('Save Profile'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
