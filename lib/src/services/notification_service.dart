import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Global notification service for showing toasts and alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  /// Initialize the notification service with a ScaffoldMessenger key
  static void initialize(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  /// Show a warning toast about fallback storage
  static void showFallbackStorageWarning() {
    final messengerState = _scaffoldMessengerKey?.currentState;
    if (messengerState != null) {
      messengerState.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Using encrypted file storage for API keys. '
                  'For better security, ensure your system has a working keyring/keychain.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () => messengerState.hideCurrentSnackBar(),
          ),
        ),
      );
    } else {
      Logger.warning('Cannot show fallback storage warning - ScaffoldMessenger not available');
    }
  }

  /// Show a success message
  static void showSuccess(String message) {
    final messengerState = _scaffoldMessengerKey?.currentState;
    if (messengerState != null) {
      messengerState.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show an error message
  static void showError(String message) {
    final messengerState = _scaffoldMessengerKey?.currentState;
    if (messengerState != null) {
      messengerState.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Show an info message
  static void showInfo(String message) {
    final messengerState = _scaffoldMessengerKey?.currentState;
    if (messengerState != null) {
      messengerState.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}