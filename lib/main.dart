import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/constants/app_config.dart';
import 'core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global error logging hooks for debug builds
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('FlutterError: ${details.exceptionAsString()}');
        debugPrintStack(stackTrace: details.stack);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught platform error: $error');
        debugPrintStack(stackTrace: stack);
      }
      return true;
    };

    // Load environment config (compile-time via --dart-define=FLAVOR=prod)
    final config = AppConfig.fromEnvironment();
    debugPrint('Starting app with config: $config');

    // Initialize Firebase and messaging; keep bootstrap robust to errors
    await FirebaseBootstrap.initialize();

    await EasyLocalization.ensureInitialized();

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: const Locale('ar'),
        saveLocale: true,
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: App(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stack);
    }
  });
}
