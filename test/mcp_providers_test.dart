import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/src/core/dependencies.dart';
import '../lib/src/services/mcp_health_service.dart';

void main() {
  group('MCP Provider Tests', () {
    test('McpConnectionMode enum has correct values', () {
      expect(McpConnectionMode.values.length, 2);
      expect(McpConnectionMode.values.contains(McpConnectionMode.local), true);
      expect(McpConnectionMode.values.contains(McpConnectionMode.remote), true);
    });

    test('mcpConnectionModeProvider has correct initial state', () {
      final container = ProviderContainer();
      final mcpMode = container.read(mcpConnectionModeProvider);
      expect(mcpMode, McpConnectionMode.remote);
      container.dispose();
    });

    test('lastUsedRemoteUrlProvider has correct initial state', () {
      final container = ProviderContainer();
      final url = container.read(lastUsedRemoteUrlProvider);
      expect(url, 'grpc-server-4rwujpfquq-uc.a.run.app');
      container.dispose();
    });

    test('mcpLatencyProvider starts with null', () {
      final container = ProviderContainer();
      final latency = container.read(mcpLatencyProvider);
      expect(latency, null);
      container.dispose();
    });

    test('mcpLatencyStatusProvider returns offline when latency is null', () {
      final container = ProviderContainer();
      final status = container.read(mcpLatencyStatusProvider);
      expect(status, LatencyStatus.offline);
      container.dispose();
    });

    test('mcpLatencyStatusProvider returns correct status based on latency', () {
      final container = ProviderContainer();
      
      // Set good latency
      container.read(mcpLatencyProvider.notifier).state = 100;
      expect(container.read(mcpLatencyStatusProvider), LatencyStatus.good);
      
      // Set medium latency
      container.read(mcpLatencyProvider.notifier).state = 300;
      expect(container.read(mcpLatencyStatusProvider), LatencyStatus.medium);
      
      // Set poor latency
      container.read(mcpLatencyProvider.notifier).state = 500;
      expect(container.read(mcpLatencyStatusProvider), LatencyStatus.poor);
      
      container.dispose();
    });
  });
}