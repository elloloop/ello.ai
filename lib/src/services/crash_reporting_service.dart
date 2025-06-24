import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for crash reporting and error tracking
class CrashReportingService {
  static bool _isInitialized = false;

  /// Initialize the crash reporting service
  static Future<void> initialize({String? sentryDsn}) async {
    if (_isInitialized) return;

    // Get Sentry DSN from environment or parameter
    final dsn = sentryDsn ?? 
        const String.fromEnvironment('SENTRY_DSN', defaultValue: '');

    if (dsn.isEmpty) {
      if (kDebugMode) {
        debugPrint('[CrashReporting] Sentry DSN not provided, crash reporting disabled');
      }
      _isInitialized = true;
      return;
    }

    try {
      await Sentry.init(
        (options) {
          options.dsn = dsn;
          options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
          options.debug = kDebugMode;
          options.environment = kDebugMode ? 'development' : 'production';
          options.attachStacktrace = true;
          options.attachScreenshot = true;
          options.captureFailedRequests = true;
          
          // Set release version if available
          options.release = const String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');
        },
      );

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('[CrashReporting] Sentry initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashReporting] Failed to initialize Sentry: $e');
      }
    }
  }

  /// Report an error to crash reporting service
  static Future<void> reportError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? message,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (message != null) {
            scope.setTag('error_message', message);
          }
          if (extra != null) {
            for (final entry in extra.entries) {
              scope.setExtra(entry.key, entry.value);
            }
          }
          scope.level = level;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashReporting] Failed to report error: $e');
      }
    }
  }

  /// Report a message to crash reporting service
  static Future<void> reportMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isInitialized) return;

    try {
      await Sentry.captureMessage(
        message,
        level: level,
        withScope: (scope) {
          if (extra != null) {
            for (final entry in extra.entries) {
              scope.setExtra(entry.key, entry.value);
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashReporting] Failed to report message: $e');
      }
    }
  }

  /// Add user context for crash reporting
  static void setUser({
    String? id,
    String? username,
    String? email,
    Map<String, dynamic>? extras,
  }) {
    if (!_isInitialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        username: username,
        email: email,
        extras: extras,
      ));
    });
  }

  /// Add custom context/tags for crash reporting
  static void setContext(String key, Map<String, dynamic> context) {
    if (!_isInitialized) return;

    Sentry.configureScope((scope) {
      scope.setContext(key, context);
    });
  }

  /// Add a breadcrumb for debugging
  static void addBreadcrumb(
    String message, {
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    if (!_isInitialized) return;

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Check if crash reporting is initialized and available
  static bool get isAvailable => _isInitialized;
}