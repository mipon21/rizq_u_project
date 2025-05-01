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

        // Pause the scanner visually (optional, as logic prevents re-processing)
        // cameraController.stop(); // Can uncomment if desired

        // Call the controller's processing logic
        restaurantController
            .processQrScan(scannedCode)
            .then((_) {
              // After processing, reset the flag and optionally restart camera
              if (mounted) {
                // Check if widget is still in the tree
                setState(() {
                  isProcessing = false; // Reset flag
                });
                // cameraController.start(); // Restart if stopped
              }
            })
            .catchError((error) {
              // Handle potential errors during processing
              if (kDebugMode) {
                print("Error processing scan via controller: $error");
              }
              if (mounted) {
                setState(() {
                  isProcessing = false; // Reset flag on error too
                });
                // cameraController.start(); // Restart if stopped
              }
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the scan window size (similar to previous implementation)
    var scanAreaWidth = MediaQuery.of(context).size.width * 0.7;
    var scanAreaHeight =
        MediaQuery.of(context).size.width * 0.7; // Make it square

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Customer QR'),
        actions: [
          // --- Updated Torch Button ---
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off, // Use local state
              color:
                  isTorchOn
                      ? Colors.yellow
                      : Colors.grey, // Change color based on state
            ),
            iconSize: 32.0,
            tooltip: isTorchOn ? 'Turn Torch Off' : 'Turn Torch On',
            onPressed: () async {
              await cameraController
                  .toggleTorch(); // Call the controller method
              setState(() {
                isTorchOn = !isTorchOn; // Update the local state
              });
            },
          ),
          // --- Switch Camera Button (Optional, keep commented if not needed) ---
          // IconButton(
          //   icon: const Icon(Icons.cameraswitch),
          //   iconSize: 32.0,
          //   tooltip: 'Switch Camera',
          //   onPressed: () async {
          //     await cameraController.switchCamera();
          //     setState(() {}); // Rebuild to reflect camera change if needed elsewhere
          //   },
          // ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            // allowDuplicates: false, // Deprecated, handle duplicates manually
            onDetect: _handleBarcodeDetection, // Use our handler
            // Define the scan window area (optional but recommended for performance)
            scanWindow: Rect.fromCenter(
              center: MediaQuery.of(
                context,
              ).size.center(Offset.zero), // Center of the screen
              width: scanAreaWidth,
              height: scanAreaHeight,
            ),
            // --- Listen for controller start/stop to update torch state ---
            // This ensures the icon is correct if the camera restarts
            // onScannerStarted: (args) {
            //   // Check initial torch state if possible (API might vary)
            //   // For now, we assume it starts off
            //   // Or try reading a property if the controller exposes one,
            //   // but generally toggleTorch is the main interaction.
            //   if (mounted) {
            //     // You *might* need to query the actual state here if the
            //     // controller provides a way, but just tracking toggles is often enough.
            //     // Example: isTorchOn = cameraController.someTorchStateGetter ?? false;
            //     // setState(() {});
            //   }
            // },
          ),
          // Custom Scan Window Overlay (replaces QrScannerOverlayShape)
          Center(
            child: Container(
              width: scanAreaWidth,
              height: scanAreaHeight,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green.withOpacity(0.7), // Color of the border
                  width: 4, // Width of the border
                ),
                borderRadius: BorderRadius.circular(12), // Rounded corners
              ),
            ),
          ),
          // Processing / Instruction Overlay
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isProcessing
                      ? 'Processing Code...'
                      : 'Align QR code within the frame',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Loading indicator from controller (for network operations)
          Obx(() {
            if (restaurantController.isLoadingScan.value) {
              // This indicator shows during the network call in processQrScan
              return Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text(
                        "Verifying Scan...",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
