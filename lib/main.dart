import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/logger.dart';
import 'core/providers.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Catch Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'Flutter framework error: ${details.exception}',
          details.exception,
          details.stack,
        );
      };

      // Catch asynchronous platform errors
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        AppLogger.error('Platform async error: $error', error, stack);
        return true;
      };

      try {
        await Firebase.initializeApp();
        AppLogger.info('Firebase initialized successfully.');
      } catch (e, stack) {
        AppLogger.error('Firebase initialization warning/error', e, stack);
      }

      runApp(
        const ProviderScope(
          observers: [AppProviderObserver()],
          child: FoodConnectApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      AppLogger.error('Uncaught Zoned Error: $error', error, stack);
    },
  );
}
