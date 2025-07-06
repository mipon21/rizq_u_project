import 'package:flutter/foundation.dart';

/// App configuration class to manage different modes and settings
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Toggle to switch between normal login and admin login
  /// Set to true for admin panel only mode
  /// Set to false for normal app mode
  static const bool isAdminPanelOnly = bool.fromEnvironment(
    'ADMIN_PANEL_ONLY',
    defaultValue: false,
  );

  /// App mode enum
  static AppMode get currentMode {
    if (isAdminPanelOnly) {
      return AppMode.adminPanel;
    }
    return AppMode.normal;
  }

  /// Check if running in admin panel mode
  static bool get isAdminMode => currentMode == AppMode.adminPanel;

  /// Check if running in normal mode
  static bool get isNormalMode => currentMode == AppMode.normal;

  /// Get the initial route based on current mode
  static String get initialRoute {
    if (isAdminMode) {
      return '/admin/login';
    }
    return '/splash';
  }

  /// Get app title based on mode
  static String get appTitle {
    if (isAdminMode) {
      return 'RIZQ Admin Panel';
    }
    return 'RIZQ APP';
  }

  /// Debug information
  static void printConfig() {
    if (kDebugMode) {
      print('=== APP CONFIGURATION ===');
      print('Admin Panel Only: $isAdminPanelOnly');
      print('Current Mode: $currentMode');
      print('Initial Route: $initialRoute');
      print('App Title: $appTitle');
      print('========================');
    }
  }
}

/// App modes enum
enum AppMode {
  normal,
  adminPanel,
} 