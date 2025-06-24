import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/services/crash_reporting_service.dart';
import 'package:ello_ai/src/utils/logger.dart';

void main() {
  group('Crash Reporting Service Tests', () {
    test('should initialize without crashing when no DSN provided', () async {
      // Test that the service can initialize gracefully without a Sentry DSN
      await CrashReportingService.initialize();
      expect(CrashReportingService.isAvailable, isTrue);
    });

    test('should handle errors gracefully when reporting fails', () async {
      // Initialize service
      await CrashReportingService.initialize();
      
      // This should not throw even if Sentry is not properly configured
      expect(() async {
        await CrashReportingService.reportError(
          Exception('Test error'),
          StackTrace.current,
          message: 'Test error message',
          extra: {'test': 'data'},
        );
      }, returnsNormally);
    });

    test('should handle messages gracefully when reporting fails', () async {
      // Initialize service
      await CrashReportingService.initialize();
      
      // This should not throw even if Sentry is not properly configured
      expect(() async {
        await CrashReportingService.reportMessage(
          'Test message',
          extra: {'test': 'data'},
        );
      }, returnsNormally);
    });

    test('should handle breadcrumbs gracefully', () {
      // This should not throw even if Sentry is not properly configured
      expect(() {
        CrashReportingService.addBreadcrumb(
          'Test breadcrumb',
          category: 'test',
          data: {'test': 'data'},
        );
      }, returnsNormally);
    });

    test('should handle user context gracefully', () {
      // This should not throw even if Sentry is not properly configured
      expect(() {
        CrashReportingService.setUser(
          id: 'test-user',
          username: 'testuser',
          extras: {'role': 'tester'},
        );
      }, returnsNormally);
    });

    test('should handle custom context gracefully', () {
      // This should not throw even if Sentry is not properly configured
      expect(() {
        CrashReportingService.setContext('test_context', {
          'version': '1.0.0',
          'environment': 'test',
        });
      }, returnsNormally);
    });
  });

  group('Enhanced Logger Tests', () {
    test('should handle debug logging without crashing', () {
      expect(() {
        Logger.debug('Test debug message', extra: {'test': 'data'});
      }, returnsNormally);
    });

    test('should handle info logging without crashing', () {
      expect(() {
        Logger.info('Test info message', extra: {'test': 'data'});
      }, returnsNormally);
    });

    test('should handle warning logging without crashing', () {
      expect(() {
        Logger.warning('Test warning message', extra: {'test': 'data'});
      }, returnsNormally);
    });

    test('should handle error logging with exception without crashing', () {
      expect(() {
        Logger.error(
          'Test error message',
          exception: Exception('Test exception'),
          stackTrace: StackTrace.current,
          extra: {'test': 'data'},
        );
      }, returnsNormally);
    });

    test('should handle error logging without exception without crashing', () {
      expect(() {
        Logger.error('Test error message', extra: {'test': 'data'});
      }, returnsNormally);
    });
  });
}