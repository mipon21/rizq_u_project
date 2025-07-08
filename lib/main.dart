// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rizq/app/bindings/initial_binding.dart';
import 'package:rizq/app/controllers/language_controller.dart';
import 'package:rizq/app/routes/app_pages.dart';
import 'package:rizq/app/theme/theme.dart';
import 'package:rizq/app/utils/translations.dart';
import 'package:rizq/app/utils/constants/app_config.dart';
import 'package:rizq/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize for release builds
  if (kReleaseMode) {
    // Disable debug prints in release
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    // For Android, use Play Integrity provider
    androidProvider: AndroidProvider.playIntegrity,
    // For iOS, use App Attest provider
    appleProvider: AppleProvider.appAttest,
  );

  // Initialize GetStorage
  await GetStorage.init();

  // Create a route observer for navigation tracking
  final routeObserver = RouteObserver<PageRoute>();

  // Print app configuration for debugging
  AppConfig.printConfig();

  // Initialize LanguageController before running the app
  Get.put<LanguageController>(LanguageController(), permanent: true);

  runApp(RizqApp(routeObserver: routeObserver));
}

class RizqApp extends StatelessWidget {
  final RouteObserver<PageRoute> routeObserver;

  const RizqApp({super.key, required this.routeObserver});

  @override
  Widget build(BuildContext context) {
    // AuthController is now lazy-loaded in InitialBinding
    final languageController = Get.find<LanguageController>();

    return GetMaterialApp(
      title: AppConfig.appTitle,
      theme: MAppTheme.lightTheme,
      // darkTheme: MAppThePme.darkTheme,
      themeMode: ThemeMode.light,
      initialBinding: InitialBinding(),
      initialRoute: AppConfig.initialRoute,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,

      // Performance optimizations
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,

      // Localization setup
      translations: AppTranslations(),
      locale: languageController.currentLocale,
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: languageController.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Register the observer for navigation
      navigatorObservers: [routeObserver],
      // home: AdminLoginPage(),
    );
  }
}
