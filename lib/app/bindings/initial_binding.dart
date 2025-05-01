import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart';

// This binding ensures the AuthController is available globally and persists
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Use put instead of lazyPut to initialize immediately
    // permanent: true ensures it stays in memory throughout the app lifecycle
    Get.put(AuthController(), permanent: true);
  }
}
