import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/customer_controller.dart'; // Adjust import
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rizq/app/utils/constants/colors.dart'; // Import qr_flutter

class QrCodePage extends GetView<CustomerController> {
  const QrCodePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userUid = controller.userUid; // Get UID from controller

    return Scaffold(
      appBar: AppBar(),
      body: Container(
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
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QrImageView(
                      // Use QrImageView from qr_flutter
                      data: userUid,
                      version: QrVersions.auto,
                      size: 250.0,
                      // You can customize appearance: foregroundColor, backgroundColor, etc.
                      // embeddedImage: AssetImage('assets/images/logo.png'), // Optional: Embed logo
                      // embeddedImageStyle: QrEmbeddedImageStyle(size: Size(40, 40)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Present this code to the restaurateur to collect points.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    // SelectableText(userUid), // Optional: Show UID for debugging
                  ],
                ),
        ),
      ),
    );
  }
}
