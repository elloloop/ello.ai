import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';

/// A widget that displays LLM parameter sliders for temperature and top-p
class LlmParameterSettings extends ConsumerWidget {
  const LlmParameterSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temperature = ref.watch(temperatureProvider);
    final topP = ref.watch(topPProvider);

    return ExpansionTile(
      leading: const Icon(Icons.tune),
      title: const Text('LLM Parameters'),
      subtitle: Text('Temperature: ${temperature.toStringAsFixed(1)}, Top-p: ${topP.toStringAsFixed(1)}'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Temperature slider
              Text(
                'Temperature: ${temperature.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Slider(
                value: temperature,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                label: temperature.toStringAsFixed(1),
                onChanged: (value) {
                  ref.read(temperatureProvider.notifier).updateTemperature(value);
                },
              ),
              Text(
                'Controls randomness. Lower = more focused, Higher = more creative',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Top-p slider
              Text(
                'Top-p: ${topP.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Slider(
                value: topP,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: topP.toStringAsFixed(1),
                onChanged: (value) {
                  ref.read(topPProvider.notifier).updateTopP(value);
                },
              ),
              Text(
                'Controls diversity. Lower = more focused vocabulary, Higher = more diverse',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              
              // Reset button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref.read(temperatureProvider.notifier).updateTemperature(0.7);
                      ref.read(topPProvider.notifier).updateTopP(1.0);
                    },
                    child: const Text('Reset to Defaults'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact widget that can be placed in the app bar or other locations
class LlmParameterCompact extends ConsumerWidget {
  const LlmParameterCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temperature = ref.watch(temperatureProvider);
    final topP = ref.watch(topPProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.tune),
      tooltip: 'LLM Parameters',
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Temperature: ${temperature.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                SizedBox(
                  width: 200,
                  child: Slider(
                    value: temperature,
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    onChanged: (value) {
                      ref.read(temperatureProvider.notifier).updateTemperature(value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Top-p: ${topP.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                SizedBox(
                  width: 200,
                  child: Slider(
                    value: topP,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) {
                      ref.read(topPProvider.notifier).updateTopP(value);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'reset',
          child: const Text('Reset to Defaults'),
        ),
      ],
      onSelected: (value) {
        if (value == 'reset') {
          ref.read(temperatureProvider.notifier).updateTemperature(0.7);
          ref.read(topPProvider.notifier).updateTopP(1.0);
        }
      },
    );
  }
}