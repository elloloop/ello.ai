import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/llm_providers.dart';

class GrpcSettingsScreen extends ConsumerWidget {
  const GrpcSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(grpcHostProvider);
    final port = ref.watch(grpcPortProvider);
    final secure = ref.watch(grpcSecureProvider);
    final useMock = ref.watch(useMockGrpcProvider);
    final useDirectApi = ref.watch(useDirectApiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Use Direct API Connection'),
              subtitle: const Text(
                  'Connect directly to OpenAI API instead of using gRPC Gateway'),
              value: useDirectApi,
              onChanged: (value) {
                ref.read(useDirectApiProvider.notifier).state = value;
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Use Mock gRPC Client'),
              subtitle:
                  const Text('Enable for testing when server is unavailable'),
              value: useMock,
              onChanged: useDirectApi
                  ? null
                  : (value) {
                      ref.read(useMockGrpcProvider.notifier).state = value;
                    },
            ),
            const Divider(),
            const Text(
              'gRPC Server Connection Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              useDirectApi
                  ? 'Server settings disabled while using direct API connection'
                  : 'Configure connection to the LLM Gateway server',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: useDirectApi ? Colors.grey : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: host,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'Enter server host (e.g., localhost)',
                border: OutlineInputBorder(),
              ),
              enabled: !useDirectApi && !useMock,
              onChanged: (value) {
                ref.read(grpcHostProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: port.toString(),
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: 'Enter server port (e.g., 50051)',
                border: OutlineInputBorder(),
              ),
              enabled: !useDirectApi && !useMock,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsedPort = int.tryParse(value);
                if (parsedPort != null) {
                  ref.read(grpcPortProvider.notifier).state = parsedPort;
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use Secure Connection (TLS)'),
              value: secure,
              onChanged: (!useDirectApi && !useMock)
                  ? (value) {
                      ref.read(grpcSecureProvider.notifier).state = value;
                    }
                  : null,
            ),
            const SizedBox(height: 32),
            const Text(
              'Note: Make sure the LLM Gateway server is running at the specified host and port.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            if (useMock) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mock mode is enabled. The app will use a simulated gRPC client for testing.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Go back to chat screen
                  Navigator.of(context).pop();
                },
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
