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
import 'package:rizq/app/services/connectivity_service.dart';
import 'package:rizq/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase App Check with appropriate provider based on platform
  if (kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        webProvider:
            ReCaptchaV3Provider('6LdB3ngrAAAAAIEJAOa_y-sErvf9NFOPxy06wsw8'),
      );
      debugPrint('Firebase App Check activated successfully for web');
    } catch (e) {
      debugPrint('Firebase App Check may already be initialized: $e');
      debugPrint('Firebase App Check initialization error: $e');
    }
  } else {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
      debugPrint('Firebase App Check activated successfully for mobile');
    } catch (e) {
      debugPrint('Firebase App Check initialization error: $e');
    }
  }

  await GetStorage.init();

  // Register RouteObserver globally
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  Get.put<RouteObserver<PageRoute>>(routeObserver, permanent: true);

  // Initialize language controller
  final languageController = Get.put(LanguageController());

  // Initialize connectivity service as permanent
  final connectivityService = Get.put(ConnectivityService(), permanent: true);

  // Add global listener for connectivity
  ever(connectivityService.isConnected, (bool isConnected) {
    if (!isConnected) {
      if (Get.currentRoute != Routes.NO_INTERNET) {
        Get.toNamed(Routes.NO_INTERNET);
      }
    } else {
      if (Get.currentRoute == Routes.NO_INTERNET && Get.key.currentState?.canPop() == true) {
        Get.back();
      }
    }
  });

  // Print app configuration for debugging
  AppConfig.printConfig();

  runApp(const RizqApp());
}

class RizqApp extends StatelessWidget {
  const RizqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final routeObserver = Get.find<RouteObserver<PageRoute>>();
    return GetMaterialApp(
      title: AppConfig.appTitle,
      theme: MAppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialBinding: InitialBinding(),
      initialRoute: AppConfig.initialRoute,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: languageController.currentLocale,
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: languageController.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [routeObserver],
    );
  }
}