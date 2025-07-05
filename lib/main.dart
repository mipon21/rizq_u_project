// ignore_for_file: unused_local_variable

import 'package:device_preview/device_preview.dart';
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
import 'package:rizq/app/ui/pages/admin/admin_login_page.dart';
import 'package:rizq/app/utils/translations.dart';
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
        // You need to replace 'recaptcha-v3-site-key' with your actual reCAPTCHA site key
        // or use ReCaptchaEnterpriseProvider if you're using Enterprise reCAPTCHA
      );
    } catch (e) {
      // Handle the case where App Check is already initialized
      debugPrint('Firebase App Check may already be initialized: $e');
    }
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
      // Use AppleProvider.appAttest for iOS
    );
  }

  await GetStorage.init();

  // Create the RouteObserver before app initialization
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  // Register the RouteObserver globally
  Get.put<RouteObserver<PageRoute>>(routeObserver, permanent: true);

  // Initialize language controller
  final languageController = Get.put(LanguageController());

  // Only use DevicePreview in debug mode when specifically needed
  // to reduce startup overhead
  if (kDebugMode && false) {
    // Set to true only when needed for device preview
    runApp(
      DevicePreview(
        enabled: true,
        builder: (context) => RizqApp(routeObserver: routeObserver),
      ),
    );
  } else {
    runApp(RizqApp(routeObserver: routeObserver));
  }
}

class RizqApp extends StatelessWidget {
  final RouteObserver<PageRoute> routeObserver;

  const RizqApp({super.key, required this.routeObserver});

  @override
  Widget build(BuildContext context) {
    // AuthController is now lazy-loaded in InitialBinding
    final languageController = Get.find<LanguageController>();

    return GetMaterialApp(
      title: 'RIZQ APP',
      theme: MAppTheme.lightTheme,
      // darkTheme: MAppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,

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
