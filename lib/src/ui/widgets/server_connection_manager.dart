import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';
import '../../utils/server_connection_util.dart';

class ServerConnectionManager extends ConsumerStatefulWidget {
  const ServerConnectionManager({Key? key}) : super(key: key);

  @override
  ConsumerState<ServerConnectionManager> createState() =>
      _ServerConnectionManagerState();
}

class _ServerConnectionManagerState
    extends ConsumerState<ServerConnectionManager> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  bool _isSecure = true;
  bool _isConnecting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();

    // Initialize with current values
    final host = ref.read(grpcHostProvider);
    final port = ref.read(grpcPortProvider);
    final secure = ref.read(grpcSecureProvider);

    _hostController.text = host;
    _portController.text = port.toString();
    _isSecure = secure;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connectToServer() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Get port from text field or use default
      final port = int.tryParse(_portController.text) ?? 443;

      // Validate host
      if (_hostController.text.isEmpty) {
        throw Exception('Host cannot be empty');
      }

      // If it looks like a Cloud Run URL, force secure connection
      if (ServerConnectionUtil.isCloudRunUrl(_hostController.text)) {
        setState(() {
          _isSecure = true;
        });
      }

      // Create connection config
      final config = GrpcConnectionConfig(
        host: _hostController.text,
        port: port,
        secure: _isSecure,
      );

      // Update providers with new values
      ref.read(grpcHostProvider.notifier).updateHost(_hostController.text);
      ref.read(grpcPortProvider.notifier).updatePort(port);
      ref.read(grpcSecureProvider.notifier).setSecure(_isSecure);

      // Initialize the connection
      final client = ref.read(chatGrpcClientProvider);
      await client.init(
        host: _hostController.text,
        port: port,
        secure: _isSecure,
      );

      // Test the connection
      final isConnected = await client.testConnection();

      if (isConnected) {
        setState(() {
          _successMessage = 'Successfully connected to server';
        });

        // If we don't have an active conversation, start one
        if (!client.hasActiveConversation) {
          try {
            final response = await client.startConversation();
            ref
                .read(conversationIdProvider.notifier)
                .setConversationId(response.conversationId);

            setState(() {
              _successMessage =
                  'Connected and started new conversation (ID: ${response.conversationId.substring(0, 8)}...)';
            });
          } catch (e) {
            print('Failed to start conversation: $e');
            // We'll create one when the first message is sent
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Connection test failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });
      print('Connection error: $e');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _useCloudRunServer() {
    final config = ServerConnectionUtil.getCloudRunConfig();
    setState(() {
      _hostController.text = config.host;
      _portController.text = config.port.toString();
      _isSecure = config.secure;
    });
  }

  void _useLocalServer() {
    final config = ServerConnectionUtil.getLocalConfig();
    setState(() {
      _hostController.text = config.host;
      _portController.text = config.port.toString();
      _isSecure = config.secure;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get connection status from provider
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == ConnectionStatus.connected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'gRPC Server Connection',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Connection status indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: isConnected ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected
                        ? 'Connected to ${_hostController.text}:${_portController.text}'
                        : 'Not connected',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Host field
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'e.g., localhost or your-server.run.app',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Port field
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: 'e.g., 50051 or 443',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // Secure connection toggle
            SwitchListTile(
              title: const Text('Use secure connection (TLS)'),
              subtitle: Text(
                _isSecure
                    ? 'Using TLS encryption (required for Cloud Run)'
                    : 'Using insecure connection (local development only)',
              ),
              value: _isSecure,
              onChanged: (value) {
                setState(() {
                  _isSecure = value;
                });
              },
            ),

            // Quick connection buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.computer),
                  label: const Text('Local Server'),
                  onPressed: _useLocalServer,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cloud),
                  label: const Text('Cloud Run'),
                  onPressed: _useCloudRunServer,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Connect button
            ElevatedButton.icon(
              icon: const Icon(Icons.power_settings_new),
              label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
              onPressed: _isConnecting ? null : _connectToServer,
            ),

            // Error/success messages
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
