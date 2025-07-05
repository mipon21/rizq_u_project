import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';

class SnackbarMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // If we're not on the customer home tab, close all snackbars
    if (route != Routes.CUSTOMER_HOME) {
      Get.closeAllSnackbars();
    }
    return null;
  }
}
