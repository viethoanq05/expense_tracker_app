import 'package:firebase_core/firebase_core.dart';
import 'package:expense_tracker_app/firebase_options.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static bool _initialized = false;
  static Object? _lastError;

  static bool get isInitialized => _initialized;
  static Object? get lastError => _lastError;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      _lastError = null;
    } catch (error) {
      _initialized = false;
      _lastError = error;
      if (kDebugMode) {
        debugPrint('Firebase initialization skipped: $error');
      }
    }
  }
}
