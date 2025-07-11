import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rizq/app/services/connectivity_service.dart';
import 'package:rizq/app/routes/app_pages.dart';

class ConnectivityMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final connectivityService = Get.find<ConnectivityService>();
    
    // Check if we have internet connection
    if (!connectivityService.hasInternetConnection) {
      // Redirect to no internet page
      return const RouteSettings(name: Routes.NO_INTERNET);
    }
    
    // Allow navigation if connected
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    // You can add additional logic here if needed
    return page;
  }

  @override
  List<Bindings>? onBindingsStart(List<Bindings>? bindings) {
    // Ensure connectivity service is available
    if (!Get.isRegistered<ConnectivityService>()) {
      Get.put(ConnectivityService());
    }
    return bindings;
  }
} 