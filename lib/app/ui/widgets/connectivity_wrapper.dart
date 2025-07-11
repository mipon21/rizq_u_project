import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/services/connectivity_service.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  
  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();

    return Obx(() {
      if (!connectivityService.isConnected.value) {
        // Show no internet page when there's no connection
        return const NoInternetPage();
      }
      
      return child;
    });
  }
}

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FF),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 60,
                  color: Color(0xFFD32F2F),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Please check your internet connection and try again. Make sure you have a stable connection to use the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D),
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
                            backgroundColor: const Color(0xFFD32F2F).withOpacity(0.1),
                            colorText: const Color(0xFFD32F2F),
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5932D2),
                  foregroundColor: Colors.white,
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
              
              const SizedBox(height: 16),
              
              // Settings Button
              TextButton(
                onPressed: () {
                  // Open device settings
                  Get.snackbar(
                    'Network Settings',
                    'Please check your device\'s network settings.',
                    backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                    colorText: const Color(0xFF1976D2),
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: const Text(
                  'Check Network Settings',
                  style: TextStyle(
                    color: Color(0xFF5932D2),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 