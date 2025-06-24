// Simple test to validate MCP health service logic
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/services/mcp_health_service.dart';

void main() {
  group('McpHealthService', () {
    test('getLatencyStatus returns correct status for different latencies', () {
      // Test good latency (≤150ms)
      expect(McpHealthService.getLatencyStatus(50), LatencyStatus.good);
      expect(McpHealthService.getLatencyStatus(150), LatencyStatus.good);
      
      // Test medium latency (≤400ms)
      expect(McpHealthService.getLatencyStatus(151), LatencyStatus.medium);
      expect(McpHealthService.getLatencyStatus(300), LatencyStatus.medium);
      expect(McpHealthService.getLatencyStatus(400), LatencyStatus.medium);
      
      // Test poor latency (>400ms)
      expect(McpHealthService.getLatencyStatus(401), LatencyStatus.poor);
      expect(McpHealthService.getLatencyStatus(1000), LatencyStatus.poor);
    });
    
    test('LatencyStatus extension provides correct display names', () {
      expect(LatencyStatus.good.displayName, 'Good');
      expect(LatencyStatus.medium.displayName, 'Medium');
      expect(LatencyStatus.poor.displayName, 'Poor');
      expect(LatencyStatus.offline.displayName, 'Offline');
    });
  });
}