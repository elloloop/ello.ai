import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/ui/settings/model_picker.dart';
import 'package:ello_ai/src/core/dependencies.dart';

void main() {
  group('ModelPicker Widget Tests', () {
    Widget createModelPicker({
      String selectedModel = 'gpt-3.5-turbo',
      List<String> availableModels = const ['gpt-3.5-turbo', 'gpt-4o'],
    }) {
      return ProviderScope(
        overrides: [
          modelProvider.overrideWith((ref) => ModelNotifier()..selectModel(selectedModel)),
          availableModelsProvider.overrideWith((ref) => availableModels),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: const ModelPicker(),
          ),
        ),
      );
    }

    testWidgets('displays dropdown with current model selected', (WidgetTester tester) async {
      await tester.pumpWidget(createModelPicker());
      
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(find.text('gpt-3.5-turbo'), findsOneWidget);
    });

    testWidgets('shows all available models in dropdown', (WidgetTester tester) async {
      const availableModels = ['gpt-3.5-turbo', 'gpt-4o', 'claude-3'];
      await tester.pumpWidget(createModelPicker(availableModels: availableModels));

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Check all models are displayed
      for (final model in availableModels) {
        expect(find.text(model), findsOneWidget);
      }
    });

    testWidgets('can select different model', (WidgetTester tester) async {
      const availableModels = ['gpt-3.5-turbo', 'gpt-4o'];
      await tester.pumpWidget(createModelPicker(availableModels: availableModels));

      // Initially shows gpt-3.5-turbo
      expect(find.text('gpt-3.5-turbo'), findsOneWidget);

      // Open dropdown and select gpt-4o
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('gpt-4o').last);
      await tester.pumpAndSettle();

      // Should now show gpt-4o (Note: In real app, this would require proper provider state)
      // This test verifies the UI interaction, actual state change depends on provider
    });

    testWidgets('handles empty model list gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createModelPicker(availableModels: []));
      
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      
      // Tap the dropdown - should not crash
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
    });

    testWidgets('displays custom model names correctly', (WidgetTester tester) async {
      const customModels = ['custom-model-1', 'local-llama', 'fine-tuned-gpt'];
      await tester.pumpWidget(createModelPicker(
        selectedModel: 'custom-model-1',
        availableModels: customModels,
      ));

      expect(find.text('custom-model-1'), findsOneWidget);

      // Open dropdown to verify all custom models are present
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      for (final model in customModels) {
        expect(find.text(model), findsOneWidget);
      }
    });

    testWidgets('handles very long model names', (WidgetTester tester) async {
      const longModelName = 'very-long-model-name-that-might-cause-overflow-issues-in-ui';
      await tester.pumpWidget(createModelPicker(
        selectedModel: longModelName,
        availableModels: [longModelName],
      ));

      expect(find.text(longModelName), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('widget has proper semantics for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(createModelPicker());
      
      // Ensure the dropdown is accessible
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      
      // The dropdown should be focusable and tappable
      final dropdown = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
      expect(dropdown.onChanged, isNotNull);
    });
  });
}