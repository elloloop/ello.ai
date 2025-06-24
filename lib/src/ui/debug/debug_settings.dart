import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';
import '../../services/chat_service_client.dart';

/// A widget that displays debug settings only in debug mode
class DebugSettingsButton extends ConsumerWidget {
  const DebugSettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDebugMode = ref.watch(isDebugModeProvider);
    final useMockGrpc = ref.watch(useMockGrpcProvider);

    // Only show the debug button in debug mode
    if (!isDebugMode) {
      return const SizedBox.shrink();
    }

    return Badge(
      label: Text(useMockGrpc ? "MOCK" : "REAL"),
      backgroundColor: useMockGrpc ? Colors.orange : Colors.green,
      child: IconButton(
        icon: Icon(useMockGrpc ? Icons.offline_bolt : Icons.bug_report),
        tooltip:
            'Debug Settings ${isDebugMode ? "(Debug Mode)" : "(Production Mode)"}',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const DebugSettingsDialog(),
          );
        },
      ),
    );
  }
}

/// Dialog that contains debug settings
class DebugSettingsDialog extends ConsumerWidget {
  const DebugSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMockGrpc = ref.watch(useMockGrpcProvider);
    final grpcHost = ref.watch(grpcHostProvider);
    final grpcPort = ref.watch(grpcPortProvider);
    final isSecure = ref.watch(grpcSecureProvider);
    final isCloudRun = grpcHost.contains('run.app');

    return AlertDialog(
      title: Row(
        children: [
          const Text('Debug Settings'),
          const Spacer(),
          if (!useMockGrpc)
            TextButton.icon(
              icon: const Icon(Icons.offline_bolt, color: Colors.orange),
              label: const Text('Enable Mock Mode',
                  style: TextStyle(color: Colors.orange)),
              onPressed: () {
                ref.read(useMockGrpcProvider.notifier).toggle();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Mock Mode enabled - using simulated responses'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current client information
            Text(
              'Current Client:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Consumer(builder: (context, ref, _) {
              final client = ref.watch(currentChatClientProvider);
              return Text(
                '${client.runtimeType}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: client.toString().contains('Mock')
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),

            const Divider(),

            // Mock gRPC toggle
            SwitchListTile(
              title: const Text('Use Mock gRPC Client'),
              subtitle: const Text('Enable to use simulated responses'),
              value: useMockGrpc,
              onChanged: (value) {
                ref.read(useMockGrpcProvider.notifier).toggle();
              },
            ),

            // Cloud Run information
            if (isCloudRun)
              const ListTile(
                leading: Icon(Icons.cloud),
                title: Text('Cloud Run Service Detected'),
                subtitle: Text('Using secure TLS connection (port 443)'),
              ),

            const Divider(),

            // gRPC connection settings
            const Text('gRPC Server Settings',
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            // Host
            Row(
              children: [
                const Text('Host: '),
                Expanded(
                  child: Text(
                    grpcHost,
                    style: const TextStyle(fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editHost(context, ref, grpcHost),
                  iconSize: 20,
                ),
              ],
            ),

            // Port
            Row(
              children: [
                const Text('Port: '),
                Text(grpcPort.toString()),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPort(context, ref, grpcPort),
                  iconSize: 20,
                ),
              ],
            ),

            // Secure connection toggle
            SwitchListTile(
              title: const Text('Use Secure Connection'),
              subtitle: const Text('Enable for TLS/SSL'),
              value: isSecure,
              onChanged: (value) {
                ref.read(grpcSecureProvider.notifier).toggle();
              },
            ),

            const Divider(),

            // Environment info
            const Text('Environment',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Debug mode: Enabled',
                style: TextStyle(color: Colors.green)),

            // Test connection button
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Test Standard gRPC'),
                    onPressed: () {
                      _testGrpcConnection(context, ref, useSecure: false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.security),
                    label: const Text('Test with TLS'),
                    onPressed: () {
                      _testGrpcConnection(context, ref, useSecure: true);
                    },
                  ),
                ),
              ],
            ),

            const Divider(),

            // Auto-fallback settings
            const Text('Connection Handling',
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            // Auto-fallback toggle
            Consumer(builder: (context, ref, _) {
              final autoFallback = ref.watch(autoFallbackToMockProvider);
              final failCount = ref.watch(connectionFailCounterProvider);
              final maxAttempts = ref.watch(maxConnectionAttemptsProvider);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Auto-fallback to Mock'),
                    subtitle: const Text(
                        'Automatically switch to mock mode after repeated connection failures'),
                    value: autoFallback,
                    onChanged: (value) {
                      ref.read(autoFallbackToMockProvider.notifier).state =
                          value;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text('Connection failures: '),
                        Text(
                          '$failCount/$maxAttempts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: failCount > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(connectionFailCounterProvider.notifier)
                                .state = 0;
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            // Setup for local development
            ref.read(grpcHostProvider.notifier).updateHost('localhost');
            ref.read(grpcPortProvider.notifier).setForDebug();

            // Ensure secure is false for local development
            if (ref.read(grpcSecureProvider)) {
              ref.read(grpcSecureProvider.notifier).toggle();
            }

            Navigator.of(context).pop();
          },
          child: const Text('Setup Local'),
        ),
        TextButton(
          onPressed: () {
            // Reset to production defaults
            ref
                .read(grpcHostProvider.notifier)
                .updateHost('grpc-server-4rwujpfquq-uc.a.run.app');
            ref.read(grpcPortProvider.notifier).setForProduction();

            // Ensure secure is true for production
            if (!ref.read(grpcSecureProvider)) {
              ref.read(grpcSecureProvider.notifier).toggle();
            }

            // Ensure mock is false for production
            if (ref.read(useMockGrpcProvider)) {
              ref.read(useMockGrpcProvider.notifier).toggle();
            }

            Navigator.of(context).pop();
          },
          child: const Text('Reset to Production'),
        ),
      ],
    );
  }

  // Edit host dialog
  void _editHost(BuildContext context, WidgetRef ref, String currentHost) {
    final controller = TextEditingController(text: currentHost);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit gRPC Host'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Host',
            hintText: 'e.g., localhost or your-server.example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(grpcHostProvider.notifier).updateHost(controller.text);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Edit port dialog
  void _editPort(BuildContext context, WidgetRef ref, int currentPort) {
    final controller = TextEditingController(text: currentPort.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit gRPC Port'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Port',
            hintText: 'e.g., 50051 or 443',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final port = int.tryParse(controller.text);
              if (port != null && port > 0) {
                ref.read(grpcPortProvider.notifier).updatePort(port);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Test gRPC connection
  void _testGrpcConnection(BuildContext context, WidgetRef ref,
      {bool useSecure = false}) async {
    final host = ref.read(grpcHostProvider);
    final port = ref.read(grpcPortProvider);
    final secure = useSecure || ref.read(grpcSecureProvider);

    final connectionType = useSecure ? 'TLS/Secure' : 'Standard gRPC';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Testing $connectionType Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
                'Connecting to $host:$port (${secure ? 'secure' : 'insecure'}) using $connectionType...'),
            const SizedBox(height: 8),
            if (useSecure && host.contains('run.app'))
              const Text(
                'Note: This uses standard gRPC with TLS for Cloud Run compatibility.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
          ],
        ),
      ),
    );

    try {
      // Create a new client for testing
      final chatGrpcClient = ChatGrpcClient();

      // Initialize the client with the requested settings
      await chatGrpcClient.init(
        host: host,
        port: port,
        secure: secure,
      );

      // Close the connection after test
      await chatGrpcClient.shutdown();

      // Success dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$connectionType Connection Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Successfully connected to $host:$port using $connectionType'),
                const SizedBox(height: 8),
                if (host.contains('run.app') && !useSecure)
                  const Text(
                    'Note: Cloud Run services typically require secure connections. Consider using TLS mode.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
              ],
            ),
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Set mock mode to false since connection is working
                  if (ref.read(useMockGrpcProvider)) {
                    ref.read(useMockGrpcProvider.notifier).toggle();
                  }

                  // Reset connection failure counter
                  ref.read(connectionFailCounterProvider.notifier).state = 0;
                },
                child: const Text('Use This Connection'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Error dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$connectionType Connection Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Failed to connect to $host:$port using $connectionType'),
                const SizedBox(height: 8),
                if (host.contains('run.app') && !useSecure)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIP: Cloud Run servers usually require TLS/Secure mode.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Try using the "Test with TLS" button instead.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                const Text('Error details:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    e.toString(),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
            icon: const Icon(Icons.error, color: Colors.red, size: 40),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Set mock mode to true since connection is failing
                  if (!ref.read(useMockGrpcProvider)) {
                    ref.read(useMockGrpcProvider.notifier).toggle();
                  }
                },
                child: const Text('Use Mock Mode'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  // No unused methods - removed _testGrpcProxyConnection and _testProxyConnection for cleaner code
}
