import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/restaurant_registration_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../ui/theme/widget_themes/cached_image_widget.dart';
import 'dart:io';

class RestaurantRegistrationPage
    extends GetView<RestaurantRegistrationController> {
  const RestaurantRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Clear any previous rejection status when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.clearRejectionStatus();
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Registration'),
        backgroundColor: MColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        return Stepper(
          currentStep: controller.currentStep.value,
          onStepContinue: () {
            if (controller.currentStep.value < 1) {
              controller.nextStep();
            } else {
              controller.submitRestaurantRegistration();
            }
          },
          onStepCancel: () {
            if (controller.currentStep.value > 0) {
              controller.previousStep();
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  if (controller.currentStep.value > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (controller.currentStep.value > 0)
                    const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(controller.currentStep.value == 1
                              ? 'Submit'
                              : 'Next'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            _buildBasicInfoStep(),
            _buildDocumentUploadStep(),
          ],
        );
      }),
    );
  }

  Step _buildBasicInfoStep() {
    return Step(
      title: const Text('Basic Information'),
      content: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Restaurant Name *',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => controller.restaurantName.value = value,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Restaurant name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Owner Name *',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => controller.ownerName.value = value,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Owner name is required' : null,
          ),
        ],
      ),
      isActive: controller.currentStep.value >= 0,
    );
  }

  Step _buildDocumentUploadStep() {
    return Step(
      title: const Text('Documents & Logo'),
      content: Column(
        children: [
          // Restaurant Logo
          _buildImageUploadSection(
            title: 'Restaurant Logo *',
            imageFile: controller.logoFile.value,
            onTap: controller.pickLogo,
            icon: Icons.restaurant,
          ),
          const SizedBox(height: 16),

          // National ID Front
          _buildImageUploadSection(
            title: 'National ID Front *',
            imageFile: controller.nationalIdFrontFile.value,
            onTap: controller.pickNationalIdFront,
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 16),

          // National ID Back
          _buildImageUploadSection(
            title: 'National ID Back *',
            imageFile: controller.nationalIdBackFile.value,
            onTap: controller.pickNationalIdBack,
            icon: Icons.credit_card,
          ),
        ],
      ),
      isActive: controller.currentStep.value >= 1,
    );
  }

  Widget _buildImageUploadSection({
    required String title,
    required File? imageFile,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: imageFile != null ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                if (imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      imageFile,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                if (imageFile != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: onTap,
                        tooltip: 'Change Image',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (imageFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Image selected',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
