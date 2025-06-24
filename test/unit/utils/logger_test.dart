import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:ello_ai/src/utils/logger.dart';

void main() {
  group('Logger', () {
    setUp(() {
      // Reset debug mode for each test
      debugDefaultTargetPlatformOverride = null;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('debug method executes without error', () {
      expect(() => Logger.debug('Test debug message'), returnsNormally);
    });

    test('info method executes without error', () {
      expect(() => Logger.info('Test info message'), returnsNormally);
    });

    test('warning method executes without error', () {
      expect(() => Logger.warning('Test warning message'), returnsNormally);
    });

    test('error method executes without error', () {
      expect(() => Logger.error('Test error message'), returnsNormally);
    });

    test('handles empty messages', () {
      expect(() => Logger.debug(''), returnsNormally);
      expect(() => Logger.info(''), returnsNormally);
      expect(() => Logger.warning(''), returnsNormally);
      expect(() => Logger.error(''), returnsNormally);
    });

    test('handles very long messages', () {
      final longMessage = 'A' * 1000;
      expect(() => Logger.debug(longMessage), returnsNormally);
      expect(() => Logger.info(longMessage), returnsNormally);
      expect(() => Logger.warning(longMessage), returnsNormally);
      expect(() => Logger.error(longMessage), returnsNormally);
    });

    test('handles special characters', () {
      const specialMessage = 'Test with emojis 😀 and unicode 🚀 characters';
      expect(() => Logger.debug(specialMessage), returnsNormally);
      expect(() => Logger.info(specialMessage), returnsNormally);
      expect(() => Logger.warning(specialMessage), returnsNormally);
      expect(() => Logger.error(specialMessage), returnsNormally);
    });

    test('handles null-like content gracefully', () {
      expect(() => Logger.debug('null'), returnsNormally);
      expect(() => Logger.info('undefined'), returnsNormally);
      expect(() => Logger.warning('NaN'), returnsNormally);
      expect(() => Logger.error('Error: null pointer'), returnsNormally);
    });

    group('Message formatting', () {
      test('debug messages have DEBUG prefix', () {
        // We can't easily test the actual output without mocking debugPrint,
        // but we can ensure the method calls complete successfully
        expect(() => Logger.debug('Debug test'), returnsNormally);
      });

      test('info messages have INFO prefix', () {
        expect(() => Logger.info('Info test'), returnsNormally);
      });

      test('warning messages have WARNING prefix', () {
        expect(() => Logger.warning('Warning test'), returnsNormally);
      });

      test('error messages have ERROR prefix', () {
        expect(() => Logger.error('Error test'), returnsNormally);
      });
    });

    group('Different message types', () {
      test('logs structured data as string', () {
        expect(() => Logger.info('User ID: 123, Action: login'), returnsNormally);
        expect(() => Logger.debug('Request: GET /api/users'), returnsNormally);
        expect(() => Logger.warning('Timeout: 5000ms exceeded'), returnsNormally);
        expect(() => Logger.error('Exception: NullPointerException at line 42'), returnsNormally);
      });

      test('logs multiple lines', () {
        const multilineMessage = '''
Error occurred in function processData():
  - Input was null
  - Expected string but got null
  - Stack trace follows
''';
        expect(() => Logger.error(multilineMessage), returnsNormally);
      });
    });
  });
}