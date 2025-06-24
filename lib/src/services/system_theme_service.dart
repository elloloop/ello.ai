import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for detecting and listening to system theme changes
class SystemThemeService {
  static const MethodChannel _channel = MethodChannel('ello.ai/system_theme');
  
  /// Get the current system theme mode
  static Future<ThemeMode> getSystemThemeMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('getSystemThemeMode');
      if (result == null) return ThemeMode.system;
      return result ? ThemeMode.light : ThemeMode.dark;
    } catch (e) {
      // Fallback to system default if platform channel fails
      return ThemeMode.system;
    }
  }

  /// Listen to system theme changes
  static void listenToSystemThemeChanges(Function(ThemeMode) onThemeChanged) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSystemThemeChanged') {
        final isDarkMode = call.arguments as bool? ?? false;
        onThemeChanged(isDarkMode ? ThemeMode.dark : ThemeMode.light);
      }
    });
  }
}