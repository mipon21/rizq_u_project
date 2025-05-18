import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart'; // Import mobile_scanner

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController cameraController = MobileScannerController();
  final RestaurantController restaurantController = Get.find();
  bool isProcessing = false; // Local flag to prevent multiple scans processing
  bool isTorchOn = false; // <--- Add local state for torch

  @override
  void dispose() {
    cameraController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (isProcessing) return; // Don't process if already processing a scan

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? scannedCode = barcodes.first.rawValue;

      if (scannedCode != null && scannedCode.isNotEmpty) {
        setState(() {
          isProcessing = true; // Set flag
        });

        if (kDebugMode) {
          print('QR Code Detected: $scannedCode');
        }

        // Call the controller's processing logic
        restaurantController.processQrScan(scannedCode).then((_) {
          // After processing, reset the flag and optionally restart camera
          if (mounted) {
            // Check if widget is still in the tree
            setState(() {
              isProcessing = false; // Reset flag
            });
          }
        }).catchError((error) {
          // Handle potential errors during processing
          if (kDebugMode) {
            print("Error processing scan via controller: $error");
          }
          if (mounted) {
            setState(() {
              isProcessing = false; // Reset flag on error too
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the scan window size - keep it square
    final size = MediaQuery.of(context).size;
    final scanAreaWidth = size.width * 0.8;
    final scanAreaHeight = scanAreaWidth; // Keep it square

    return Scaffold(
      // No app bar as requested
      extendBody: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: _handleBarcodeDetection,
              scanWindow: Rect.fromCenter(
                center: Offset(
                    size.width / 2, size.height * 0.5), // Center of the screen
                width: scanAreaWidth,
                height: scanAreaHeight,
              ),
            ),
            // Torch Button - Positioned at top right
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: isTorchOn ? Colors.yellow : Colors.white,
                  ),
                  iconSize: 28.0,
                  tooltip: isTorchOn ? 'Turn Torch Off' : 'Turn Torch On',
                  onPressed: () async {
                    await cameraController.toggleTorch();
                    setState(() {
                      isTorchOn = !isTorchOn;
                    });
                  },
                ),
              ),
            ),
            // Custom Scan Window Overlay
            Positioned(
              top: size.height * 0.5 - scanAreaHeight / 1.2,
              left: size.width / 2 - scanAreaWidth / 2,
              child: Container(
                width: scanAreaWidth,
                height: scanAreaHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green.withOpacity(0.8),
                    width: 3.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            // "Verifying Scan..." overlay
            Obx(() {
              if (restaurantController.isLoadingScan.value) {
                return Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.purpleAccent,
                          strokeWidth: 5,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Verifying Scan...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            // Processing / Instruction Overlay
            Positioned(
              bottom: 70,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isProcessing
                        ? 'Processing Code...'
                        : 'Align QR code within the frame',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
