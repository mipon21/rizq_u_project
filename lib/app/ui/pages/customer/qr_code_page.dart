import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/customer_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../services/contact_service.dart';
import '../../../utils/constants/support_constants.dart';

class QrCodePage extends GetView<CustomerController> {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userUid = controller.userUid;

    // Check daily point limit when page is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.checkDailyPointLimit();
    });

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: userUid.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Could not load user ID.'),
                ],
              )
            : Obx(() {
                final profile = controller.customerProfile.value;
                
                // If customer is restricted, show restriction page
                if (profile?.isRestricted == true) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      // Restriction message
                      const Text(
                        'Account Restricted',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Restriction reason
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          profile?.restrictionReason ?? 'Admin restriction',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '[Admin has restricted your account.Please contact support for assistance.]',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Contact support button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ContactService.sendEmail(
                              email: SupportConstants.supportEmail,
                              subject: 'Account Restriction Appeal - ${profile?.name ?? 'Customer'}',
                              message: 'Dear Support Team,\n\n'
                                  'I would like to appeal the restriction of my account.\n\n'
                                  'Customer Name: ${profile?.name ?? 'N/A'}\n'
                                  'Customer Email: ${profile?.email ?? 'N/A'}\n'
                                  'Restriction Reason: ${profile?.restrictionReason ?? 'Admin restriction'}\n\n'
                                  'Please review my account status and let me know how to proceed.\n\n'
                                  'Thank you for your assistance.\n\n'
                                  'Best regards,\n'
                                  '${profile?.name ?? 'Customer'}',
                            );
                          },
                          icon: const Icon(Icons.email, color: Colors.white),
                          label: const Text(
                            'Contact Support',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                    ],
                  );
                }
                
                // Normal QR code display
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QrImageView(
                      data: userUid,
                      version: QrVersions.auto,
                      size: 250.0,
                    ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Present this code to the restaurants to collect points.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                );
              }),
      ),
    );
  }
}
