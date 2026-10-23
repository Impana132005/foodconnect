import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ [INFO]: $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ [WARN]: $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('🚨 [ERROR]: $message');
      if (error != null) {
        print('Details: $error');
      }
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      print('🛠️ [DEBUG]: $message');
    }
  }
}
