import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/restaurant_registration_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../ui/theme/widget_themes/cached_image_widget.dart';

class RestaurantRegistrationPage
    extends GetView<RestaurantRegistrationController> {
  const RestaurantRegistrationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            if (controller.currentStep.value < 3) {
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
                          : Text(controller.currentStep.value == 3
                              ? 'Submit Registration'
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
            _buildContactInfoStep(),
            _buildBankInfoStep(),
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
            imageUrl: controller.logoUrl.value,
            isLoading: controller.isUploadingLogo.value,
            onTap: controller.pickAndUploadLogo,
            icon: Icons.restaurant,
          ),
          const SizedBox(height: 16),

          // National ID Front
          _buildImageUploadSection(
            title: 'National ID Front *',
            imageUrl: controller.nationalIdFrontUrl.value,
            isLoading: controller.isUploadingIdFront.value,
            onTap: controller.pickAndUploadNationalIdFront,
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 16),

          // National ID Back
          _buildImageUploadSection(
            title: 'National ID Back *',
            imageUrl: controller.nationalIdBackUrl.value,
            isLoading: controller.isUploadingIdBack.value,
            onTap: controller.pickAndUploadNationalIdBack,
            icon: Icons.credit_card,
          ),
        ],
      ),
      isActive: controller.currentStep.value >= 1,
    );
  }

  Step _buildContactInfoStep() {
    return Step(
      title: const Text('Contact Information'),
      content: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Support Email *',
              border: OutlineInputBorder(),
              helperText: 'Email for customer support inquiries',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => controller.supportEmail.value = value,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Support email is required';
              }
              if (!GetUtils.isEmail(value!)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ],
      ),
      isActive: controller.currentStep.value >= 2,
    );
  }

  Step _buildBankInfoStep() {
    return Step(
      title: const Text('Bank Information'),
      content: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Bank Details *',
              border: OutlineInputBorder(),
              helperText: 'Bank name and account holder name',
            ),
            onChanged: (value) => controller.bankDetails.value = value,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Bank details are required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'IBAN Number *',
              border: OutlineInputBorder(),
              helperText: 'International Bank Account Number',
            ),
            onChanged: (value) => controller.ibanNumber.value = value,
            validator: (value) =>
                value?.isEmpty ?? true ? 'IBAN number is required' : null,
          ),
        ],
      ),
      isActive: controller.currentStep.value >= 3,
    );
  }

  Widget _buildImageUploadSection({
    required String title,
    required String imageUrl,
    required bool isLoading,
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
          onTap: isLoading ? null : onTap,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    imageUrl.isNotEmpty ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedImageWidget(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        Icon(
                          icon,
                          size: (32).isFinite && 32 > 0 ? 32 : 24,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        if (imageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: (16).isFinite && 16 > 0 ? 16 : 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Uploaded successfully',
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
