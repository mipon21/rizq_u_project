import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/customer_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/constants/colors.dart';

class QrCodePage extends GetView<CustomerController> {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userUid = controller.userUid;

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
            : Column(
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
              ),
      ),
    );
  }
}
