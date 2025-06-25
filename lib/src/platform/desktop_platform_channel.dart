import 'package:flutter/services.dart';
import 'dart:io';

/// Desktop platform channel for ello.AI
/// Provides desktop-specific functionality and system integration
class DesktopPlatformChannel {
  static const MethodChannel _channel = MethodChannel('ello.ai/desktop');

  /// Get the current platform information
  static Future<Map<String, dynamic>> getPlatformInfo() async {
    try {
      final result = await _channel.invokeMethod('getPlatformInfo');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      // Return basic info if platform channel is not available
      return {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'error': e.message,
      };
    }
  }

  /// Set the application title (for desktop windows)
  static Future<bool> setWindowTitle(String title) async {
    try {
      await _channel.invokeMethod('setWindowTitle', {'title': title});
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// Request system notifications permission (desktop specific)
  static Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod('requestNotificationPermission');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  /// Show system notification
  static Future<bool> showNotification({
    required String title,
    required String body,
    String? iconPath,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
        'iconPath': iconPath,
      });
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// Get system theme (light/dark)
  static Future<String> getSystemTheme() async {
    try {
      final result = await _channel.invokeMethod('getSystemTheme');
      return result ?? 'light';
    } on PlatformException {
      return 'light';
    }
  }

  /// Set application to start on system startup
  static Future<bool> setStartOnBoot(bool enable) async {
    try {
      await _channel.invokeMethod('setStartOnBoot', {'enable': enable});
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// Get application version information
  static Future<Map<String, String>> getAppVersion() async {
    try {
      final result = await _channel.invokeMethod('getAppVersion');
      return Map<String, String>.from(result ?? {});
    } on PlatformException {
      return {};
    }
  }

  /// Check if running as administrator/root (for privileged operations)
  static Future<bool> isRunningAsAdmin() async {
    try {
      final result = await _channel.invokeMethod('isRunningAsAdmin');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  /// Minimize application to system tray (if supported)
  static Future<bool> minimizeToTray() async {
    try {
      await _channel.invokeMethod('minimizeToTray');
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// Show application from system tray
  static Future<bool> showFromTray() async {
    try {
      await _channel.invokeMethod('showFromTray');
      return true;
    } on PlatformException {
      return false;
    }
  }
}