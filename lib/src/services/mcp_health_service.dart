import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Service to handle MCP (Model Control Protocol) health checks
class McpHealthService {
  static const String localHost = '127.0.0.1';
  static const int localPort = 5100;
  static const String healthEndpoint = '/healthz';
  
  /// Check the health of the local MCP server
  /// Returns the latency in milliseconds if successful, null if failed
  static Future<int?> checkLocalHealth() async {
    try {
      final uri = Uri.http('$localHost:$localPort', healthEndpoint);
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Health check timeout', const Duration(seconds: 5)),
      );
      
      stopwatch.stop();
      final latencyMs = stopwatch.elapsedMilliseconds;
      
      if (response.statusCode == 200) {
        Logger.info('Local MCP health check successful - ${latencyMs}ms');
        return latencyMs;
      } else {
        Logger.warning('Local MCP health check failed - HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Logger.warning('Local MCP health check failed: $e');
      return null;
    }
  }
  
  /// Check if local MCP server is available
  static Future<bool> isLocalAvailable() async {
    final latency = await checkLocalHealth();
    return latency != null;
  }
  
  /// Get latency color based on response time
  static LatencyStatus getLatencyStatus(int latencyMs) {
    if (latencyMs <= 150) {
      return LatencyStatus.good;
    } else if (latencyMs <= 400) {
      return LatencyStatus.medium;
    } else {
      return LatencyStatus.poor;
    }
  }
}

/// Represents the latency status with color coding
enum LatencyStatus {
  good,    // Green - ≤150ms
  medium,  // Amber - ≤400ms  
  poor,    // Red - >400ms
  offline, // Gray - No connection
}

extension LatencyStatusExtension on LatencyStatus {
  String get displayName {
    switch (this) {
      case LatencyStatus.good:
        return 'Good';
      case LatencyStatus.medium:
        return 'Medium';
      case LatencyStatus.poor:
        return 'Poor';
      case LatencyStatus.offline:
        return 'Offline';
    }
  }
}