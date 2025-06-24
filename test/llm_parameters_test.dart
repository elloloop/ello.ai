import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/ui/settings/llm_parameters.dart';
import 'package:ello_ai/src/core/dependencies.dart';

void main() {
  group('LLM Parameter Settings Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget makeTestWidget(Widget child) {
      return ProviderScope(
        parent: container,
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets('LlmParameterSettings displays temperature and top-p sliders',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestWidget(const LlmParameterSettings()));

      // Check for the expansion tile
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.text('LLM Parameters'), findsOneWidget);

      // Expand the tile
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Check for sliders
      expect(find.byType(Slider), findsNWidgets(2));
      
      // Check for temperature and top-p labels
      expect(find.textContaining('Temperature'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Top-p'), findsAtLeastNWidgets(1));

      // Check for reset button
      expect(find.text('Reset to Defaults'), findsOneWidget);
    });

    testWidgets('Temperature slider updates value correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestWidget(const LlmParameterSettings()));

      // Expand the tile
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Find the first slider (temperature)
      final tempSlider = find.byType(Slider).first;
      
      // Initial value should be 0.7
      expect(container.read(temperatureProvider), 0.7);

      // Drag the slider to a new position
      await tester.drag(tempSlider, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Value should have changed
      expect(container.read(temperatureProvider), isNot(0.7));
    });

    testWidgets('Top-p slider updates value correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestWidget(const LlmParameterSettings()));

      // Expand the tile
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Find the second slider (top-p)
      final topPSlider = find.byType(Slider).at(1);
      
      // Initial value should be 1.0
      expect(container.read(topPProvider), 1.0);

      // Drag the slider to a new position
      await tester.drag(topPSlider, const Offset(-50, 0));
      await tester.pumpAndSettle();

      // Value should have changed
      expect(container.read(topPProvider), lessThan(1.0));
    });

    testWidgets('Reset button resets values to defaults',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestWidget(const LlmParameterSettings()));

      // Expand the tile
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Change the values first
      container.read(temperatureProvider.notifier).updateTemperature(1.5);
      container.read(topPProvider.notifier).updateTopP(0.5);
      await tester.pumpAndSettle();

      // Verify values are changed
      expect(container.read(temperatureProvider), 1.5);
      expect(container.read(topPProvider), 0.5);

      // Tap reset button
      await tester.tap(find.text('Reset to Defaults'));
      await tester.pumpAndSettle();

      // Verify values are reset
      expect(container.read(temperatureProvider), 0.7);
      expect(container.read(topPProvider), 1.0);
    });

    testWidgets('LlmParameterCompact displays popup menu',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestWidget(const LlmParameterCompact()));

      // Check for the popup menu button
      expect(find.byType(PopupMenuButton), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);

      // Tap to open the popup
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();

      // Check for sliders in the popup
      expect(find.byType(Slider), findsNWidgets(2));
      expect(find.text('Reset to Defaults'), findsOneWidget);
    });

    testWidgets('Parameter values are clamped correctly', (WidgetTester tester) async {
      // Test temperature clamping
      container.read(temperatureProvider.notifier).updateTemperature(-0.5);
      expect(container.read(temperatureProvider), 0.0);

      container.read(temperatureProvider.notifier).updateTemperature(3.0);
      expect(container.read(temperatureProvider), 2.0);

      // Test top-p clamping
      container.read(topPProvider.notifier).updateTopP(-0.5);
      expect(container.read(topPProvider), 0.0);

      container.read(topPProvider.notifier).updateTopP(1.5);
      expect(container.read(topPProvider), 1.0);
    });
  });
}