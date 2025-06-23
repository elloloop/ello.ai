import 'package:flutter/foundation.dart';
import '../core/dependencies.dart';

/// Server connection utility to handle different server environments
class ServerConnectionUtil {
  /// Get configuration for local development server
  static GrpcConnectionConfig getLocalConfig() {
    return const GrpcConnectionConfig(
      host: 'localhost',
      port: 50051, // Common local development port for gRPC
      secure: false,
    );
  }

  /// Get configuration for Cloud Run deployed server
  static GrpcConnectionConfig getCloudRunConfig({String? customUrl}) {
    // Default URL from previous deployment or use custom URL if provided
    final host = customUrl ?? 'grpc-server-4rwujpfquq-uc.a.run.app';

    // Cloud Run always uses HTTPS (port 443) with TLS
    return GrpcConnectionConfig(
      host: host,
      port: 443,
      secure: true,
    );
  }

  /// Get configuration for custom server
  static GrpcConnectionConfig getCustomConfig({
    required String host,
    required int port,
    bool secure = false,
  }) {
    return GrpcConnectionConfig(
      host: host,
      port: port,
      secure: secure,
    );
  }

  /// Detect if we're likely connecting to a Cloud Run instance
  static bool isCloudRunUrl(String host) {
    return host.contains('run.app') ||
        host.contains('cloud') ||
        host.endsWith('.a.run.app');
  }

  /// Get connection configuration based on environment
  static GrpcConnectionConfig getConnectionConfig({
    bool preferLocalForDebug = true,
    String? customUrl,
  }) {
    // In debug mode, prefer local server if requested
    if (kDebugMode && preferLocalForDebug) {
      return getLocalConfig();
    }

    // Otherwise use Cloud Run config
    return getCloudRunConfig(customUrl: customUrl);
  }

  /// Format a friendly connection string for display
  static String getConnectionString(GrpcConnectionConfig config) {
    return '${config.host}:${config.port} (${config.secure ? 'secure' : 'insecure'})';
  }
}
