import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration derived from platform config files.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not supported for Firebase in this project.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOptions are not configured for this platform: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApGnLYLOhvC-2r-0dWMTQqT450vvlijTI',
    appId: '1:930092950206:android:ca0ff118073472894cf4ef',
    messagingSenderId: '930092950206',
    projectId: 'signature-unit',
    storageBucket: 'signature-unit.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArEcN8eNKNj4pt7CnMzSOXs_p7zcQI-Ws',
    appId: '1:930092950206:ios:97a421296cbbcea14cf4ef',
    messagingSenderId: '930092950206',
    projectId: 'signature-unit',
    storageBucket: 'signature-unit.firebasestorage.app',
    iosBundleId: 'com.signature.unit.real',
  );
}
