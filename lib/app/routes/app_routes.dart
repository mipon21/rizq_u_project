part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  // General Routes
  static const SPLASH = '/splash';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const FORGOT_PASSWORD = '/forgot-password';
  static const EMAIL_VERIFICATION = '/email-verification';

  // Customer Routes
  static const CUSTOMER_HOME = '/customer/home';
  static const CUSTOMER_QR_CODE = '/customer/qr-code';
  static const CUSTOMER_SCAN_HISTORY = '/customer/scan-history';
  static const CUSTOMER_PROFILE = '/customer/profile';

  // Restaurant Routes
  static const RESTAURANT_DASHBOARD = '/restaurant/dashboard';
  static const RESTAURANT_PROFILE_SETUP = '/restaurant/profile-setup';
  static const RESTAURANT_PROGRAM_CONFIG = '/restaurant/program-config';
  static const RESTAURANT_QR_SCANNER = '/restaurant/qr-scanner';
  static const RESTAURANT_SUBSCRIPTION = '/restaurant/subscription';
  static const RESTAURANT_REGISTRATION = '/restaurant-registration';
  static const RESTAURANT_PENDING_APPROVAL = '/restaurant-pending-approval';

  // Admin Routes
  static const ADMIN_LOGIN = '/admin/login';
  static const ADMIN_DASHBOARD = '/admin/dashboard';
  static const ADMIN_RESTAURANTS = '/admin/restaurants';
  static const ADMIN_CUSTOMERS = '/admin/customers';
  static const ADMIN_REPORTS = '/admin/reports';
  static const ADMIN_CUSTOM_SUBSCRIPTION_PLANS =
      '/admin/custom-subscription-plans';
  static const ADMIN_RESTAURANT_REGISTRATIONS =
      '/admin/restaurant-registrations';
}
