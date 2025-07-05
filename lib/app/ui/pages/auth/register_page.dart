import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // Adjust import
import 'package:rizq/app/routes/app_pages.dart'; // Adjust import
import '../../../utils/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterPage extends GetView<AuthController> {
  const RegisterPage({Key? key}) : super(key: key);

  // Static method to launch Privacy Policy URL
  static Future<void> launchPrivacyPolicy() async {
    // Demo URL - replace with actual privacy policy URL later
    final Uri url = Uri.parse('https://example.com/privacy-policy');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'Error',
        'Could not launch the privacy policy page',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Static method to launch Terms and Conditions URL
  static Future<void> launchTermsAndConditions() async {
    // Demo URL - replace with actual terms and conditions URL later
    final Uri url = Uri.parse('https://example.com/terms-and-conditions');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'Error',
        'Could not launch the terms and conditions page',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final RxString selectedRole = 'customer'.obs; // Default role
    final RxBool agreedToTerms = false.obs; // Terms and Conditions checkbox
    final RxBool isPasswordVisible = false.obs;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // const SizedBox(height: 50),
                // Image.asset('assets/icons/general-u.png', height: 150),
                // const SizedBox(height: 20),
                Text(
                  'Create Your Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                Obx(
                  () => TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          isPasswordVisible.value = !isPasswordVisible.value;
                        },
                      ),
                      // helperText:
                      //     'Must contain capital letter, \nlowercase letter, \nnumber, and \nspecial character',
                    ),
                    obscureText: !isPasswordVisible.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Password must contain at least 1 capital letter';
                      }
                      if (!RegExp(r'[a-z]').hasMatch(value)) {
                        return 'Password must contain at least 1 lowercase letter';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Password must contain at least 1 number';
                      }
                      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                        return 'Password must contain at least 1 special character';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Obx(
                  () => TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          isPasswordVisible.value = !isPasswordVisible.value;
                        },
                      ),
                    ),
                    obscureText: !isPasswordVisible.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Register as a:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: 'customer',
                                groupValue: selectedRole.value,
                                visualDensity: VisualDensity.compact,
                                onChanged: (value) =>
                                    selectedRole.value = value!,
                              ),
                              Text('Customer'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: 'restaurant',
                                groupValue: selectedRole.value,
                                visualDensity: VisualDensity.compact,
                                onChanged: (value) =>
                                    selectedRole.value = value!,
                              ),
                              Text('Restaurant'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => CheckboxListTile(
                    value: agreedToTerms.value,
                    onChanged: (value) => agreedToTerms.value = value ?? false,
                    title: Wrap(
                      children: [
                        const Text('I agree to the '),
                        InkWell(
                          onTap: () => RegisterPage.launchPrivacyPolicy(),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: MColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Text(' and '),
                        InkWell(
                          onTap: () => RegisterPage.launchTermsAndConditions(),
                          child: const Text(
                            'Terms and Conditions',
                            style: TextStyle(
                              color: MColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          controller.isLoading.value || !agreedToTerms.value
                              ? null
                              : () {
                                  if (formKey.currentState!.validate()) {
                                    controller.register(
                                      emailController.text.trim(),
                                      passwordController.text.trim(),
                                      selectedRole.value,
                                    );
                                  }
                                },
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Register'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () =>
                      Get.offAllNamed(Routes.LOGIN), // Go back to login
                  child: const Text("Already have an account? Login"),
                ),
                const SizedBox(height: 20),
                // TextButton(
                //   onPressed: () =>
                //       Get.offAllNamed(Routes.ADMIN_LOGIN), // Go back to login
                //   child: const Text("Admin? Login here"),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
