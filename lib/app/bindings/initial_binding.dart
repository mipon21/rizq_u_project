import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

// This binding ensures controllers are available globally and persist
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Use put with permanent to prevent multiple instances
    // but make the heavy operations lazy inside the controller
    Get.put<AuthController>(AuthController(), permanent: true);
    
    // Register AdminController for admin screens - permanent to prevent recreation
    Get.put<AdminController>(AdminController(), permanent: true);

    // RouteObserver is now registered in main.dart
  }
}
