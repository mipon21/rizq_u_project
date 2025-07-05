import 'package:get/get.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/program_controller.dart';
import '../controllers/restaurant_registration_controller.dart';
import '../controllers/admin_controller.dart';
// Import AuthController if needed
// import 'package:rizq/app/controllers/auth_controller.dart';

class RestaurantBinding extends Bindings {
  @override
  void dependencies() {
    // Initializes RestaurantController when a restaurant route is accessed
    Get.lazyPut<RestaurantController>(() => RestaurantController());
    // Initializes ProgramController as well, needed for program config page
    Get.lazyPut<ProgramController>(() => ProgramController());
    // Initializes RestaurantRegistrationController for registration pages
    Get.lazyPut<RestaurantRegistrationController>(
        () => RestaurantRegistrationController());
    // Ensure AdminController is accessible for subscription plans
    Get.lazyPut<AdminController>(() => AdminController(), fenix: true);
    // Ensure AuthController is accessible if needed
    // Get.lazyPut<AuthController>(() => AuthController()); // Usually not needed here
  }
}
