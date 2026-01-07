import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:real_state/firebase_options.dart';

import '../../features/notifications/data/services/fcm_service.dart';

/// Initializes Firebase and performs lightweight messaging setup.
///
/// - Calls [Firebase.initializeApp].
/// - Registers background handler for messaging so navigation can work after taps.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
      debugPrint('Firebase initialized');
    } catch (e, st) {
      // Keep logging minimal and safe; errors are surface-level for dev debugging
      debugPrint('Firebase initialization failed: $e');
      debugPrint('Stack: ${st.toString().split('\n').first}');
    }
  }
}
