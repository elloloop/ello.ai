import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/llm_providers.dart';

class ModelPicker extends ConsumerWidget {
  const ModelPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(modelProvider);
    return DropdownButton<String>(
      value: model,
      onChanged: (value) {
        if (value != null) {
          ref.read(modelProvider.notifier).state = value;
        }
      },
      items: const [
        DropdownMenuItem(value: 'OpenAI', child: Text('OpenAI')),
      ],
    );
  }
}
