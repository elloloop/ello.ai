// This is a basic Flutter widget test for the ello.AI chat application.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/main.dart';
import 'package:ello_ai/src/core/dependencies.dart';
import 'package:ello_ai/src/ui/home_page.dart';

void main() {
  group('ElloApp Widget Tests', () {
    ProviderContainer makeMockedContainer() {
      return ProviderContainer(overrides: [
        chatHistoryProvider.overrideWith((ref) => ChatHistoryNotifier()),
        connectionStatusProvider
            .overrideWith((ref) => ConnectionStatusNotifier()..setConnected()),
        useMockGrpcProvider.overrideWith((ref) => MockGrpcNotifier()..toggle()),
        modelProvider.overrideWith((ref) => ModelNotifier()),
        systemPromptProvider.overrideWith((ref) => SystemPromptNotifier()),
        availableModelsProvider
            .overrideWith((ref) => ['gpt-3.5-turbo', 'gpt-4o']),
        isDebugModeProvider.overrideWith((ref) => true),
        grpcHostProvider
            .overrideWith((ref) => GrpcHostNotifier()..updateHost('mock-host')),
        grpcPortProvider
            .overrideWith((ref) => GrpcPortNotifier()..updatePort(1234)),
        grpcSecureProvider
            .overrideWith((ref) => GrpcSecureNotifier()..setSecure(false)),
        initConnectionStatusProvider.overrideWith((ref) {}),
        // Add more overrides as needed for other providers
      ]);
    }

    Future<void> pumpApp(
        WidgetTester tester, ProviderContainer container) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('App displays correct title', (WidgetTester tester) async {
      final container = makeMockedContainer();
      await pumpApp(tester, container);
      expect(find.text('ello.AI'), findsOneWidget);
    });

    testWidgets('App has proper Material Design structure',
        (WidgetTester tester) async {
      final container = makeMockedContainer();
      await pumpApp(tester, container);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Chat input interface is present', (WidgetTester tester) async {
      final container = makeMockedContainer();
      await pumpApp(tester, container);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Say something...'), findsOneWidget);
    });

    testWidgets('App bar contains expected action buttons',
        (WidgetTester tester) async {
      final container = makeMockedContainer();
      await pumpApp(tester, container);
      expect(find.byType(IconButton), findsWidgets);
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsAtLeastNWidgets(2));
    });

    testWidgets('Chat messages list view is present',
        (WidgetTester tester) async {
      final container = makeMockedContainer();
      await pumpApp(tester, container);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('System prompt override section is present',
        (WidgetTester tester) async {
      final container = makeMockedContainer();
      await pumpApp(tester, container);
      
      // Look for the system prompt expansion tile
      expect(find.text('System Prompt Override'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
      
      // Tap to expand the system prompt section
      await tester.tap(find.text('System Prompt Override'));
      await tester.pumpAndSettle();
      
      // Check that the text field appears
      expect(find.text('Enter custom system prompt (optional)...'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('System prompt can be entered and cleared',
        (WidgetTester tester) async {
      final container = makeMockedContainer();
      await pumpApp(tester, container);
      
      // Expand the system prompt section
      await tester.tap(find.text('System Prompt Override'));
      await tester.pumpAndSettle();
      
      // Find the system prompt text field
      final systemPromptField = find.byType(SystemPromptTextField);
      expect(systemPromptField, findsOneWidget);
      
      // Also check for the actual TextField inside
      final textField = find.descendant(
        of: systemPromptField,
        matching: find.byType(TextField),
      );
      expect(textField, findsOneWidget);
      
      // Enter some text in the actual TextField
      await tester.enterText(textField, 'Test system prompt');
      await tester.pumpAndSettle();
      
      // Check that the "Active" indicator appears
      expect(find.text('Active'), findsOneWidget);
      
      // Clear the system prompt
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      
      // Check that the "Active" indicator disappears
      expect(find.text('Active'), findsNothing);
    });
  });
}
