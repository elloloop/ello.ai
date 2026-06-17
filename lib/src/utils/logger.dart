import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../services/crash_reporting_service.dart';

/// Simple logger utility for the app with crash reporting integration
class Logger {
  static void debug(String message, {Map<String, dynamic>? extra}) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
    
    // Add as breadcrumb for debugging context
    CrashReportingService.addBreadcrumb(
      message,
      category: 'debug',
      level: SentryLevel.debug,
      data: extra,
    );
  }

  static void info(String message, {Map<String, dynamic>? extra}) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
    
    // Add as breadcrumb for debugging context
    CrashReportingService.addBreadcrumb(
      message,
      category: 'info',
      level: SentryLevel.info,
      data: extra,
    );
  }

  static void warning(String message, {Map<String, dynamic>? extra}) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
    
    // Report warnings to crash reporting for monitoring
    CrashReportingService.reportMessage(
      message,
      level: SentryLevel.warning,
      extra: extra,
    );
  }

  static void error(String message, {
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
    }
    
    // Report errors to crash reporting service
    if (exception != null) {
      CrashReportingService.reportError(
        exception,
        stackTrace ?? StackTrace.current,
        message: message,
        extra: extra,
      );
    } else {
      CrashReportingService.reportMessage(
        message,
        level: SentryLevel.error,
        extra: extra,
      );
    }
  }
}
