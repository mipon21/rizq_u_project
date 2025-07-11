import 'package:get/get.dart';
import 'package:rizq/app/services/connectivity_service.dart';
import 'package:rizq/app/routes/app_pages.dart';

class ConnectivityHelper {
  /// Check if device has internet connection
  static bool get hasConnection {
    final connectivityService = Get.find<ConnectivityService>();
    return connectivityService.hasInternetConnection;
  }

  /// Show no internet page
  static void showNoInternetPage() {
    Get.toNamed(Routes.NO_INTERNET);
  }

  /// Check connectivity and show no internet page if disconnected
  static Future<bool> checkAndShowNoInternet() async {
    final connectivityService = Get.find<ConnectivityService>();
    final isConnected = await connectivityService.checkConnectivity();
    
    if (!isConnected) {
      showNoInternetPage();
    }
    
    return isConnected;
  }

  /// Wrap a function with connectivity check
  static Future<T?> withConnectivityCheck<T>(
    Future<T> Function() function, {
    bool showNoInternetPage = true,
  }) async {
    final connectivityService = Get.find<ConnectivityService>();
    
    if (!connectivityService.hasInternetConnection) {
      if (showNoInternetPage) {
        ConnectivityHelper.showNoInternetPage();
      }
      return null;
    }
    
    try {
      return await function();
    } catch (e) {
      // If function fails due to network issues, show no internet page
      if (showNoInternetPage) {
        ConnectivityHelper.showNoInternetPage();
      }
      rethrow;
    }
  }
} 