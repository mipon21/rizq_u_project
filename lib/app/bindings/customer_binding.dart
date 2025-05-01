import 'package:get/get.dart';
import 'package:rizq/app/controllers/customer_controller.dart';
// Import AuthController if needed within CustomerController or its pages
// import 'package:rizq/app/controllers/auth_controller.dart';

// Binding for customer-specific screens
class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    // Initializes CustomerController when a customer route is accessed
    Get.lazyPut<CustomerController>(() => CustomerController());
    // If AuthController is needed, ensure it's accessible (already put by InitialBinding)
    // Get.lazyPut<AuthController>(() => AuthController()); // Usually not needed here
  }
}
