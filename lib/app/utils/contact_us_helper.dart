import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants/colors.dart';
import 'constants/support_constants.dart';
import '../controllers/restaurant_controller.dart';

class ContactUsHelper {

  // Direct Contact Us - opens Gmail immediately with restaurant info only
  static void showContactUsDialog(BuildContext context) {
    // Directly launch email app with empty subject and description
    // Only restaurant information will be included in the email body
    launchEmailApp(
      SupportConstants.supportEmail,
      '', // Empty subject
      '', // Empty description - restaurant info will be added automatically in launchEmailApp
    );
  }

  // Launch email app with pre-filled information
  static Future<void> launchEmailApp(String email, String subject, String body) async {
    final controller = Get.find<RestaurantController>();
    final profile = controller.restaurantProfile.value;
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Create email body with footer
    final completeBody = '''
$body

Regards,
${ 'Restaurant Name: ${profile?.name ?? 'Restaurant'}'}
${ 'Restaurant Email: $userEmail'}
${ 'Restaurant UID: $uid'}
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
        // Safely pop the dialog if it's still mounted
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
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
  static void _showEmailCopyDialog(String email, String subject, String body) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Email Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
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
  static Widget _buildCopyableField(String label, String content, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
  static void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      'Text copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // Helper method to encode query parameters
  static String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
} 