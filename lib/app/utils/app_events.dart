import 'package:get/get.dart';

/// A centralized class for app-wide events using GetX reactivity
class AppEvents {
  /// Navigate to a specific tab in the main customer navigation
  /// -1 means no action, 0-3 represents different tabs
  static final RxInt navigateToTab = (-1).obs;
}
