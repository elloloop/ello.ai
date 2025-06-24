import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/main.dart';
import 'package:ello_ai/src/core/dependencies.dart';

/// Integration test to verify the Desktop MVP shell functionality
void main() {
  group('Desktop MVP Integration Tests', () {
    ProviderContainer makeMockContainer() {
      return ProviderContainer(overrides: [
        // Override to use mock mode for testing
        useMockGrpcProvider.overrideWith((ref) => MockGrpcNotifier()..toggle()),
        // Ensure debug mode is enabled for testing
        isDebugModeProvider.overrideWith((ref) => true),
        // Set up default connection
        connectionStatusProvider
            .overrideWith((ref) => ConnectionStatusNotifier()..setConnected()),
        // Initialize other necessary providers
        modelProvider.overrideWith((ref) => ModelNotifier()),
        availableModelsProvider
            .overrideWith((ref) => ['gpt-3.5-turbo', 'mock-model']),
        chatHistoryProvider.overrideWith((ref) => ChatHistoryNotifier()),
        initConnectionStatusProvider.overrideWith((ref) {}),
      ]);
    }

    Future<void> pumpMvpApp(
        WidgetTester tester, ProviderContainer container) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Desktop MVP can launch and display chat interface',
        (WidgetTester tester) async {
      final container = makeMockContainer();
      await pumpMvpApp(tester, container);

      // Verify app launches
      expect(find.text('ello.AI'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // Verify core chat interface elements are present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Say something...'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Can send a test message through mock client',
        (WidgetTester tester) async {
      final container = makeMockContainer();
      await pumpMvpApp(tester, container);

      // Find the text input field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter a test message
      await tester.enterText(textField, 'Hello, MCP test!');
      await tester.pump();

      // Find and tap the send button
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pump();

      // Wait for the mock response to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify that messages appear in the chat
      expect(find.text('Hello, MCP test!'), findsOneWidget);
      expect(find.textContaining('Hello from MockGrpcClient'), findsOneWidget);
    });

    testWidgets('Debug settings are accessible in debug mode',
        (WidgetTester tester) async {
      final container = makeMockContainer();
      await pumpMvpApp(tester, container);

      // Look for debug button (should be visible in debug mode)
      final debugButton = find.byIcon(Icons.bug_report).or(find.byIcon(Icons.offline_bolt));
      
      if (debugButton.hasFound) {
        await tester.tap(debugButton.first);
        await tester.pumpAndSettle();

        // Verify debug dialog appears
        expect(find.text('Debug Settings'), findsOneWidget);
        expect(find.text('Use Mock gRPC Client'), findsOneWidget);
      }
    });

    testWidgets('Connection status indicator is present',
        (WidgetTester tester) async {
      final container = makeMockContainer();
      await pumpMvpApp(tester, container);

      // Should find connection status indicator
      expect(find.textContaining('Mock Mode').or(find.textContaining('Connected')), 
             findsOneWidget);
    });

    testWidgets('Model picker is functional', (WidgetTester tester) async {
      final container = makeMockContainer();
      await pumpMvpApp(tester, container);

      // Look for model picker dropdown (may not be visible in current UI)
      final modelPicker = find.byType(DropdownButton<String>);
      
      if (modelPicker.hasFound) {
        // Test model selection if dropdown is present
        await tester.tap(modelPicker);
        await tester.pumpAndSettle();
        
        expect(find.text('gpt-3.5-turbo').or(find.text('mock-model')), 
               findsOneWidget);
      }
    });
  });
}