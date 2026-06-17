import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';
import '../../services/mcp_health_service.dart';

/// Widget that displays MCP connection status and latency badge
class McpLatencyBadge extends ConsumerWidget {
  const McpLatencyBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mcpMode = ref.watch(mcpConnectionModeProvider);
    final latencyStatus = ref.watch(mcpLatencyStatusProvider);
    final latency = ref.watch(mcpLatencyProvider);
    
    // Get the appropriate color and icon based on latency status
    Color badgeColor;
    IconData icon;
    String tooltip;
    
    switch (latencyStatus) {
      case LatencyStatus.good:
        badgeColor = Colors.green;
        icon = Icons.signal_cellular_4_bar;
        tooltip = 'Good connection (${latency}ms)';
        break;
      case LatencyStatus.medium:
        badgeColor = Colors.amber;
        icon = Icons.signal_cellular_3_bar;
        tooltip = 'Medium connection (${latency}ms)';
        break;
      case LatencyStatus.poor:
        badgeColor = Colors.red;
        icon = Icons.signal_cellular_1_bar;
        tooltip = 'Poor connection (${latency}ms)';
        break;
      case LatencyStatus.offline:
        badgeColor = Colors.grey;
        icon = Icons.signal_cellular_off;
        tooltip = 'Offline';
        break;
    }
    
    String modeText = mcpMode == McpConnectionMode.local ? "LOCAL" : "REMOTE";
    
    return Badge(
      label: Text(
        modeText,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: badgeColor,
      child: IconButton(
        icon: Icon(icon),
        tooltip: '$tooltip - $modeText MCP',
        onPressed: () {
          _showMcpStatusDialog(context, ref);
        },
      ),
    );
  }
  
  void _showMcpStatusDialog(BuildContext context, WidgetRef ref) {
    final mcpMode = ref.read(mcpConnectionModeProvider);
    final latency = ref.read(mcpLatencyProvider);
    final latencyStatus = ref.read(mcpLatencyStatusProvider);
    final grpcHost = ref.read(grpcHostProvider);
    final grpcPort = ref.read(grpcPortProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MCP Connection Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Mode: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(mcpMode == McpConnectionMode.local ? 'Local' : 'Remote'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Server: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$grpcHost:$grpcPort'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(
                  _getStatusIcon(latencyStatus),
                  color: _getStatusColor(latencyStatus),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  latency != null ? '${latency}ms (${latencyStatus.displayName})' : latencyStatus.displayName,
                  style: TextStyle(color: _getStatusColor(latencyStatus)),
                ),
              ],
            ),
            if (mcpMode == McpConnectionMode.local) ...[
              const SizedBox(height: 16),
              const Text(
                'Local MCP Server',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• Health endpoint: 127.0.0.1:5100/healthz\n'
                '• Latency monitored every 30 seconds\n'
                '• Auto-fallback to remote if unavailable',
                style: TextStyle(fontSize: 12),
              ),
            ],
            if (mcpMode == McpConnectionMode.remote) ...[
              const SizedBox(height: 16),
              const Text(
                'Remote MCP Server',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• Fallback from local server\n'
                '• Production Cloud Run instance\n'
                '• Secure TLS connection',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (mcpMode == McpConnectionMode.remote)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryLocalConnection(ref);
              },
              child: const Text('Retry Local'),
            ),
        ],
      ),
    );
  }
  
  void _retryLocalConnection(WidgetRef ref) async {
    // Manually trigger a local health check
    ref.invalidate(autoMcpModeProvider);
  }
  
  Color _getStatusColor(LatencyStatus status) {
    switch (status) {
      case LatencyStatus.good:
        return Colors.green;
      case LatencyStatus.medium:
        return Colors.amber;
      case LatencyStatus.poor:
        return Colors.red;
      case LatencyStatus.offline:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(LatencyStatus status) {
    switch (status) {
      case LatencyStatus.good:
        return Icons.signal_cellular_4_bar;
      case LatencyStatus.medium:
        return Icons.signal_cellular_3_bar;
      case LatencyStatus.poor:
        return Icons.signal_cellular_1_bar;
      case LatencyStatus.offline:
        return Icons.signal_cellular_off;
    }
  }
}