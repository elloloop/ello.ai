import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';
import 'debug_settings.dart';

/// Displays a connectivity badge in the UI to show if mock or real client is being used
class ConnectionStatusBadge extends ConsumerWidget {
  final double size;
  final bool showText;

  const ConnectionStatusBadge({
    super.key,
    this.size = 10.0,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMock = ref.watch(useMockGrpcProvider);
    final client = ref.watch(currentChatClientProvider);
    final clientType = client.toString();

    final bool isMock = useMock || clientType.contains('Mock');
    final Color color = isMock ? Colors.orange : Colors.green;
    final String text = isMock ? 'MOCK' : 'REAL';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shows a dialog with detailed connection information
void showConnectionInfoDialog(BuildContext context, WidgetRef ref) {
  final host = ref.read(grpcHostProvider);
  final port = ref.read(grpcPortProvider);
  final secure = ref.read(grpcSecureProvider);
  final useMock = ref.read(useMockGrpcProvider);
  final client = ref.read(currentChatClientProvider);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Connection Information'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Client:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${client.runtimeType}',
              style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(height: 16),
          const Text('gRPC Settings:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Host: $host', style: const TextStyle(fontFamily: 'monospace')),
          Text('Port: $port', style: const TextStyle(fontFamily: 'monospace')),
          Text('Secure: $secure',
              style: const TextStyle(fontFamily: 'monospace')),
          Text('Mock Mode: $useMock',
              style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(height: 16),
          const Text('Connection Status:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Text('Status: '),
              ConnectionStatusBadge(showText: true),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (context) => const DebugSettingsDialog(),
            );
          },
          child: const Text('Open Debug Settings'),
        ),
      ],
    ),
  );
}
