import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';

class SnackbarUtils {
  static bool isOnCustomerHomeTab() {
    final currentRoute = Get.currentRoute;
    return currentRoute == Routes.CUSTOMER_HOME;
  }

  static void showReward(String restaurantName) {
    // Only show snackbar if we're on the customer home tab
    if (!isOnCustomerHomeTab()) return;

    Get.closeAllSnackbars();

    // Show the snackbar
    Get.snackbar(
      'Reward Available!',
      'You have a reward ready to claim at $restaurantName',
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.white,
      colorText: Colors.purple,
      snackPosition: SnackPosition.TOP,
      dismissDirection: DismissDirection.vertical,
      isDismissible: true,
      icon: const Icon(Icons.card_giftcard, color: Colors.purple),
    );
  }

  static void showError(String message) {
    Get.closeAllSnackbars();
    Get.snackbar(
      'Error',
      message,
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade900,
      snackPosition: SnackPosition.BOTTOM,
      dismissDirection: DismissDirection.vertical,
      isDismissible: true,
      icon: const Icon(Icons.error_outline, color: Colors.red),
    );
  }
}
