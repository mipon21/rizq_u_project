import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/services/connectivity_service.dart';
import 'package:rizq/app/utils/constants/colors.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();

    return Scaffold(
      backgroundColor: MColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: MColors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: MColors.grey.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 60,
                  color: MColors.error,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Please check your internet connection and try again. Make sure you have a stable connection to use the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: MColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Retry Button
              Obx(() => ElevatedButton(
                onPressed: connectivityService.isConnected.value
                    ? () {
                        // Navigate back when connection is restored
                        Get.back();
                      }
                    : () async {
                        // Show loading
                        Get.dialog(
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                          barrierDismissible: false,
                        );
                        
                        // Check connectivity
                        final isConnected = await connectivityService.checkConnectivity();
                        
                        // Close loading dialog
                        Get.back();
                        
                        if (isConnected) {
                          Get.back(); // Navigate back to previous page
                        } else {
                          // Show error message
                          Get.snackbar(
                            'Still No Connection',
                            'Please check your internet connection and try again.',
                            backgroundColor: MColors.error.withOpacity(0.1),
                            colorText: MColors.error,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10)
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primary,
                  foregroundColor: MColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectivityService.isConnected.value
                          ? Icons.check_circle
                          : Icons.refresh,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connectivityService.isConnected.value
                          ? 'Connection Restored'
                          : 'Try Again',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
            
            ],
          ),
        ),
      ),
    );
  }
} 