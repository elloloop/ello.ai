import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';

class ModelPicker extends ConsumerWidget {
  const ModelPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(modelProvider);
    final availableModels = ref.watch(availableModelsProvider);

    return DropdownButton<String>(
      value: model,
      onChanged: (value) {
        if (value != null) {
          ref.read(modelProvider.notifier).selectModel(value);
        }
      },
      items: availableModels.map((String modelName) {
        return DropdownMenuItem<String>(
          value: modelName,
          child: Text(modelName),
        );
      }).toList(),
    );
  }
}
