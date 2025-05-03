import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart';
import 'package:rizq/app/controllers/admin_controller.dart';
import 'package:flutter/material.dart';

// This binding ensures controllers are available globally and persist
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Use put instead of lazyPut to initialize immediately
    // permanent: true ensures it stays in memory throughout the app lifecycle
    Get.put(AuthController(), permanent: true);

    // Register AdminController for admin screens
    Get.put(AdminController(), permanent: true);

    // RouteObserver is now registered in main.dart
  }
}
