import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';

class SettingsPanel extends ConsumerStatefulWidget {
  const SettingsPanel({super.key});

  @override
  ConsumerState<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<SettingsPanel> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _showKeys = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each provider
    final providers = ref.read(modelProvidersProvider);
    for (final provider in providers) {
      _controllers[provider.id] = TextEditingController();
      _showKeys[provider.id] = false;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(modelProvidersProvider);
    final apiKeys = ref.watch(apiKeysProvider);
    final validationResults = ref.watch(apiKeyValidationProvider);
    final selectedModel = ref.watch(modelProvider);
    final availableModels = ref.watch(availableModelsProvider);

    // Update controllers with current API keys
    for (final provider in providers) {
      final currentKey = apiKeys[provider.id] ?? '';
      if (_controllers[provider.id]!.text != currentKey) {
        _controllers[provider.id]!.text = currentKey;
      }
    }

    return AlertDialog(
      title: const Text('Model & API Key Settings'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Model Selection
              Text(
                'Current Model',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: availableModels.contains(selectedModel) ? selectedModel : null,
                hint: const Text('Select a model'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: availableModels.map((String model) {
                  // Find which provider this model belongs to
                  final provider = providers.firstWhere(
                    (p) => p.models.contains(model),
                    orElse: () => providers.first,
                  );
                  return DropdownMenuItem<String>(
                    value: model,
                    child: Text('${provider.name}: $model'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(modelProvider.notifier).selectModel(value);
                  }
                },
              ),
              
              if (availableModels.isEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No models available. Please add at least one API key below.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              
              // API Keys Section
              Text(
                'API Keys',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Add your API keys to access models from different providers. Only providers with valid keys will show their models.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // API Key inputs for each provider
              ...providers.map((provider) {
                final hasKey = (apiKeys[provider.id] ?? '').isNotEmpty;
                final validationError = validationResults[provider.id] ?? '';
                final hasError = validationError.isNotEmpty;
                final availableModelCount = hasKey && !hasError ? provider.models.length : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              provider.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (hasKey && !hasError)
                            Chip(
                              label: Text('${availableModelCount} models'),
                              backgroundColor: Colors.green.shade100,
                              side: BorderSide(color: Colors.green.shade300),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      TextFormField(
                        controller: _controllers[provider.id],
                        obscureText: !(_showKeys[provider.id] ?? false),
                        decoration: InputDecoration(
                          labelText: provider.apiKeyName,
                          hintText: 'Enter your ${provider.name} API key',
                          border: const OutlineInputBorder(),
                          errorText: hasError ? validationError : null,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  (_showKeys[provider.id] ?? false)
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showKeys[provider.id] = !(_showKeys[provider.id] ?? false);
                                  });
                                },
                              ),
                              if (hasKey)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _controllers[provider.id]!.clear();
                                    ref.read(apiKeysProvider.notifier).removeApiKey(provider.id);
                                    _showValidationToast(context, '${provider.name} API key removed');
                                  },
                                ),
                            ],
                          ),
                        ),
                        onChanged: (value) {
                          ref.read(apiKeysProvider.notifier).setApiKey(provider.id, value.trim());
                        },
                      ),
                      
                      if (hasKey && !hasError) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: provider.models.map((model) {
                            return Chip(
                              label: Text(model),
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate all keys and show summary
            _showValidationSummary(context, providers, validationResults, apiKeys);
          },
          child: const Text('Validate All'),
        ),
      ],
    );
  }

  void _showValidationToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showValidationSummary(
    BuildContext context,
    List<ModelProvider> providers,
    Map<String, String> validationResults,
    Map<String, String> apiKeys,
  ) {
    final validProviders = <String>[];
    final invalidProviders = <String>[];
    final missingProviders = <String>[];

    for (final provider in providers) {
      final key = apiKeys[provider.id] ?? '';
      if (key.isEmpty) {
        missingProviders.add(provider.name);
      } else {
        final error = validationResults[provider.id] ?? '';
        if (error.isEmpty) {
          validProviders.add(provider.name);
        } else {
          invalidProviders.add(provider.name);
        }
      }
    }

    String message;
    Color backgroundColor;
    IconData icon;

    if (validProviders.isNotEmpty && invalidProviders.isEmpty) {
      message = 'All configured API keys are valid! (${validProviders.join(", ")})';
      backgroundColor = Colors.green;
      icon = Icons.check_circle;
    } else if (invalidProviders.isNotEmpty) {
      message = 'Invalid keys: ${invalidProviders.join(", ")}';
      backgroundColor = Colors.red;
      icon = Icons.error;
    } else {
      message = 'No API keys configured. Add keys to access models.';
      backgroundColor = Colors.orange;
      icon = Icons.warning;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Button to open the settings panel
class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Model & API Key Settings',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const SettingsPanel(),
        );
      },
    );
  }
}