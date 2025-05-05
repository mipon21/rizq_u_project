import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_controller.dart';

// Binding for authentication-related screens (Login, Register, Forgot Password)
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // lazyPut only initializes the controller when it's first used on the page
    // It will use the existing instance created by InitialBinding if available
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
