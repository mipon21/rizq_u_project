import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';
import '../utils/constants/support_constants.dart';

class ContactService {
  static Future<void> sendEmail({
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      // Get customer information
      final customerController = Get.find<CustomerController>();
      final authController = Get.find<AuthController>();
      final profile = customerController.customerProfile.value;
      final userId = authController.currentUserUid;

      // Create a formatted message with footer containing customer information
      final String messageWithFooter = '$message\n\n---------------------------\nSent from Rizq App\nCustomer Information:\nName: ${profile?.name ?? "N/A"}\nEmail: ${profile?.email ?? "N/A"}\nUser ID: $userId';

      await _launchEmail(
        email: email,
        subject: subject,
        body: messageWithFooter,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending email: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to send email. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  static Future<void> _launchEmail({
    required String email,
    required String subject,
    required String body,
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters({
        'subject': subject,
        'body': body,
      }),
    );

    try {
      final bool launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      );

      if (!launched) {
        _showEmailFallbackDialog(email, subject, body);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching email client: $e');
      }
      _showEmailFallbackDialog(email, subject, body);
    }
  }

  static void _showEmailFallbackDialog(String email, String subject, String body) {
    Get.dialog(
      AlertDialog(
        title: const Text('Email Client Not Available'),
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
          ElevatedButton(
            onPressed: () {
              Get.back();
              Clipboard.setData(ClipboardData(
                  text: 'To: $email\nSubject: $subject\n\n$body'));
              Get.snackbar(
                'Copied',
                'All email details copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Copy All'),
          ),
        ],
      ),
    );
  }

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
                icon: const Icon(Icons.copy, color: Colors.blue),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  Get.snackbar(
                    'Copied',
                    'Text copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                },
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  static Future<String> getRestaurantEmail(String restaurantId) async {
    String contactEmail = SupportConstants.supportEmail;

    try {
      // First try to get from restaurants collection
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      if (restaurantDoc.exists) {
        Map<String, dynamic>? data =
            restaurantDoc.data() as Map<String, dynamic>?;

        if (data != null &&
            data.containsKey('email') &&
            data['email'] != null &&
            data['email'].toString().isNotEmpty) {
          contactEmail = data['email'];
          return contactEmail;
        }

        // If not found in restaurant document, try to get from users collection
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(restaurantId)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic>? userData =
                userDoc.data() as Map<String, dynamic>?;

            if (userData != null &&
                userData.containsKey('email') &&
                userData['email'] != null &&
                userData['email'].toString().isNotEmpty) {
              contactEmail = userData['email'];
              return contactEmail;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching user document: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching restaurant email: $e');
      }
    }

    return contactEmail;
  }
} 