// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rizq/app/bindings/initial_binding.dart';
import 'package:rizq/app/routes/app_pages.dart';
import 'package:rizq/app/theme/theme.dart';
import 'package:rizq/app/ui/pages/admin/admin_login_page.dart';
import 'package:rizq/app/ui/theme/app_theme.dart';
import 'package:rizq/app/controllers/auth_controller.dart';
import 'package:rizq/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    // Use AppleProvider.appAttest for iOS
  );

  await GetStorage.init();

  // Create the RouteObserver before app initialization
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  // Register the RouteObserver globally
  Get.put<RouteObserver<PageRoute>>(routeObserver, permanent: true);

  runApp(RizqApp(routeObserver: routeObserver));
}

class RizqApp extends StatelessWidget {
  final RouteObserver<PageRoute> routeObserver;

  const RizqApp({super.key, required this.routeObserver});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());

    return GetMaterialApp(
      title: 'Rizq Loyalty App',
      theme: MAppTheme.lightTheme,
      darkTheme: MAppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      // Register the observer for navigation
      navigatorObservers: [routeObserver],
      // home:  AdminLoginPage(),
    );
  }
}
