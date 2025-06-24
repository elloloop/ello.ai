import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';
import '../../services/api_key_vault.dart';
import '../../utils/logger.dart';

/// Widget for managing API keys securely
class ApiKeyManager extends ConsumerStatefulWidget {
  const ApiKeyManager({super.key});

  @override
  ConsumerState<ApiKeyManager> createState() => _ApiKeyManagerState();
}

class _ApiKeyManagerState extends ConsumerState<ApiKeyManager> {
  final _openaiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _showKey = false;
  String? _currentKey;

  @override
  void initState() {
    super.initState();
    _loadCurrentKey();
  }

  @override
  void dispose() {
    _openaiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentKey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vault = await ref.read(apiKeyVaultProvider.future);
      final key = await vault.getOpenAIKey();
      setState(() {
        _currentKey = key;
        if (key != null) {
          _openaiKeyController.text = key;
        }
      });
    } catch (e) {
      Logger.error('Failed to load API key: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load API key: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _openaiKeyController.text.trim();
    
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid API key'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vault = await ref.read(apiKeyVaultProvider.future);
      await vault.storeOpenAIKey(key);
      
      // Refresh the OpenAI API key provider
      ref.invalidate(openaiApiKeyProvider);
      
      // Update the chat client to use the new key
      final chatClientNotifier = ref.read(currentChatClientProvider.notifier);
      chatClientNotifier.updateClient();

      setState(() {
        _currentKey = key;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to save API key: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save API key: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeApiKey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vault = await ref.read(apiKeyVaultProvider.future);
      await vault.removeOpenAIKey();
      
      // Refresh the OpenAI API key provider
      ref.invalidate(openaiApiKeyProvider);
      
      // Update the chat client
      final chatClientNotifier = ref.read(currentChatClientProvider.notifier);
      chatClientNotifier.updateClient();

      setState(() {
        _currentKey = null;
        _openaiKeyController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to remove API key: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove API key: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'API Key Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your API keys are stored securely using platform-specific secure storage.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            
            // OpenAI API Key section
            const Text(
              'OpenAI API Key',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _openaiKeyController,
                      obscureText: !_showKey,
                      decoration: InputDecoration(
                        hintText: 'Enter your OpenAI API key',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _showKey = !_showKey;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveApiKey,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                  if (_currentKey != null)
                    OutlinedButton.icon(
                      onPressed: _removeApiKey,
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Security info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Security Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• macOS: Stored in Keychain\n'
                      '• Windows: Stored using DPAPI\n'
                      '• Linux: Stored using libsecret\n'
                      '• Fallback: AES-256 encrypted file',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}