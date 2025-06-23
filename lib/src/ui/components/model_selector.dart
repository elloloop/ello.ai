import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/llm_providers.dart';

class ModelSelector extends ConsumerWidget {
  const ModelSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModel = ref.watch(modelProvider);
    final availableModels = ref.watch(availableModelsProvider);

    return DropdownButton<String>(
      value: currentModel,
      onChanged: (String? newValue) {
        if (newValue != null) {
          ref.read(modelProvider.notifier).state = newValue;
        }
      },
      items: availableModels.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
