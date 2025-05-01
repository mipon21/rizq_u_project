import 'package:get/get.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart';
import 'package:rizq/app/controllers/program_controller.dart';
// Import AuthController if needed
// import 'package:rizq/app/controllers/auth_controller.dart';

class RestaurantBinding extends Bindings {
  @override
  void dependencies() {
    // Initializes RestaurantController when a restaurant route is accessed
    Get.lazyPut<RestaurantController>(() => RestaurantController());
    // Initializes ProgramController as well, needed for program config page
    Get.lazyPut<ProgramController>(() => ProgramController());
    // Ensure AuthController is accessible if needed
    // Get.lazyPut<AuthController>(() => AuthController()); // Usually not needed here
  }
}
