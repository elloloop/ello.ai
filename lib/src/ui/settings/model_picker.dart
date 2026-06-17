import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';
import 'settings_panel.dart';

class ModelPicker extends ConsumerWidget {
  const ModelPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(modelProvider);
    final availableModels = ref.watch(availableModelsProvider);
    final providers = ref.watch(modelProvidersProvider);

    // Find the provider for the current model
    final currentProvider = providers.firstWhere(
      (p) => p.models.contains(model),
      orElse: () => providers.first,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Model dropdown
        Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          child: DropdownButton<String>(
            value: availableModels.contains(model) ? model : null,
            hint: const Text('Select Model'),
            isExpanded: true,
            underline: const SizedBox(),
            onChanged: (value) {
              if (value != null) {
                ref.read(modelProvider.notifier).selectModel(value);
              }
            },
            items: availableModels.isEmpty
                ? [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No models available'),
                    ),
                  ]
                : availableModels.map((String modelName) {
                    // Find which provider this model belongs to
                    final provider = providers.firstWhere(
                      (p) => p.models.contains(modelName),
                      orElse: () => providers.first,
                    );
                    return DropdownMenuItem<String>(
                      value: modelName,
                      child: Text('${provider.name}: $modelName'),
                    );
                  }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        // Settings button
        const SettingsButton(),
      ],
    );
  }
}
