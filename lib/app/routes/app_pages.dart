import 'package:get/get.dart';
import '../ui/pages/restaurant/tabs/profile_tab.dart';
import '../ui/pages/restaurant/tabs/program_settings_tab.dart';
import '../bindings/admin_binding.dart';
import '../bindings/auth_binding.dart';
import '../bindings/customer_binding.dart';
import '../bindings/restaurant_binding.dart';
import '../middleware/admin_middleware.dart';
import '../ui/pages/admin/admin_login_page.dart';
import '../ui/pages/admin/customer_management_page.dart';
import '../ui/pages/admin/dashboard_page.dart';
import '../ui/pages/admin/reports_page.dart';
import '../ui/pages/admin/restaurant_management_page.dart';
import '../ui/pages/admin/restaurant_registrations_page.dart';
import '../ui/pages/admin/custom_subscription_plans_page.dart';
import '../ui/pages/auth/login_page.dart';
import '../ui/pages/auth/register_page.dart';
import '../ui/pages/auth/restaurant_registration_page.dart';
import '../ui/pages/auth/customer_registration_page.dart';
import '../ui/pages/auth/forgot_password_page.dart';
import '../ui/pages/auth/email_verification_page.dart';
import '../ui/pages/customer/customer_home_page.dart';
import '../ui/pages/customer/scan_history_page.dart';
import '../ui/pages/customer/qr_code_page.dart';
import '../ui/pages/customer/customer_profile_page.dart';
import '../ui/pages/restaurant/dashboard_page.dart';
import '../ui/pages/restaurant/pending_approval_page.dart';

import '../ui/pages/restaurant/tabs/qr_scanner_page.dart';
import '../ui/pages/restaurant/subscription_page.dart';
import '../ui/pages/splash_page.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  // Create admin middleware instance
  static final adminMiddleware = [AdminMiddleware()];

  static final routes = [
    GetPage(name: Routes.SPLASH, page: () => const SplashPage()),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.EMAIL_VERIFICATION,
      page: () => const EmailVerificationPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.CUSTOMER_REGISTRATION,
      page: () => const CustomerRegistrationPage(),
      binding: CustomerBinding(),
    ),
    // Customer Routes
    GetPage(
      name: Routes.CUSTOMER_HOME,
      page: () => const CustomerHomePage(),
      binding: CustomerBinding(),
    ),
    GetPage(
      name: Routes.CUSTOMER_QR_CODE,
      page: () => const QrCodePage(),
      binding: CustomerBinding(),
    ),
    GetPage(
      name: Routes.CUSTOMER_SCAN_HISTORY,
      page: () => const ScanHistoryPage(),
      binding: CustomerBinding(),
    ),
    GetPage(
      name: Routes.CUSTOMER_PROFILE,
      page: () => const CustomerProfilePage(),
      binding: CustomerBinding(),
    ),
    // Restaurant Routes
    GetPage(
      name: Routes.RESTAURANT_DASHBOARD,
      page: () => const DashboardPage(),
      binding: RestaurantBinding(),
    ),
    GetPage(
      name: Routes.RESTAURANT_PROFILE_SETUP,
      page: () => const ProfileTab(),
      binding: RestaurantBinding(),
    ),
    GetPage(
      name: Routes.RESTAURANT_PROGRAM_CONFIG,
      page: () => const ProgramSettingsTab(),
      binding: RestaurantBinding(),
    ),
    GetPage(
      name: Routes.RESTAURANT_QR_SCANNER,
      page: () => const QrScannerPage(),
      binding: RestaurantBinding(),
    ),
    GetPage(
      name: Routes.RESTAURANT_SUBSCRIPTION,
      page: () => const SubscriptionPage(),
      binding: RestaurantBinding(),
    ),
    GetPage(
      name: Routes.RESTAURANT_REGISTRATION,
      page: () => const RestaurantRegistrationPage(),
      binding: RestaurantBinding(),
    ),
    GetPage(
      name: Routes.RESTAURANT_PENDING_APPROVAL,
      page: () => const PendingApprovalPage(),
      binding: RestaurantBinding(),
    ),
    // Admin Routes
    GetPage(
      name: Routes.ADMIN_LOGIN,
      page: () => const AdminLoginPage(),
      binding: AdminBinding(),
    ),
    GetPage(
      name: Routes.ADMIN_DASHBOARD,
      page: () => const AdminDashboardPage(),
      binding: AdminBinding(),
      // Comment out middleware temporarily for testing
      // middlewares: adminMiddleware,
    ),
    GetPage(
      name: Routes.ADMIN_RESTAURANTS,
      page: () => const RestaurantManagementPage(),
      binding: AdminBinding(),
      middlewares: adminMiddleware,
    ),
    GetPage(
      name: Routes.ADMIN_RESTAURANT_REGISTRATIONS,
      page: () => const RestaurantRegistrationsPage(),
      binding: AdminBinding(),
      middlewares: adminMiddleware, // Re-enabled after admin setup
    ),
    GetPage(
      name: Routes.ADMIN_CUSTOMERS,
      page: () => const CustomerManagementPage(),
      binding: AdminBinding(),
      middlewares: adminMiddleware,
    ),
    GetPage(
      name: Routes.ADMIN_REPORTS,
      page: () => const ReportsPage(),
      binding: AdminBinding(),
      middlewares: adminMiddleware,
    ),
    GetPage(
      name: Routes.ADMIN_CUSTOM_SUBSCRIPTION_PLANS,
      page: () => const CustomSubscriptionPlansPage(),
      binding: AdminBinding(),
      middlewares: adminMiddleware,
    ),
  ];
}
