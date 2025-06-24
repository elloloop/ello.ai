// This is a comprehensive Flutter widget test for the ello.AI chat application.
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
import 'helpers/test_helpers.dart';

void main() {
  group('ElloApp Widget Tests', () {
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

    group('Basic App Structure', () {
      testWidgets('App displays correct title', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer();
        await pumpApp(tester, container);
        expect(find.text('ello.AI'), findsOneWidget);
      });

      testWidgets('App has proper Material Design structure',
          (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer();
        await pumpApp(tester, container);
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('Chat input interface is present', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer();
        await pumpApp(tester, container);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.send), findsOneWidget);
        expect(find.text('Say something...'), findsOneWidget);
      });

      testWidgets('App bar contains expected action buttons',
          (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer();
        await pumpApp(tester, container);
        expect(find.byType(IconButton), findsWidgets);
        final iconButtons = find.byType(IconButton);
        expect(iconButtons, findsAtLeastNWidgets(2));
      });

      testWidgets('Chat messages list view is present',
          (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer();
        await pumpApp(tester, container);
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Connection Status Display', () {
      testWidgets('shows mock mode indicator', (WidgetTester tester) async {
        final container = TestHelpers.createMockScenario();
        await pumpApp(tester, container);
        expect(find.text('Mock Mode'), findsOneWidget);
      });

      testWidgets('shows connected status', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(
          useMockGrpc: false,
          connectionStatus: ConnectionStatus.connected,
        );
        await pumpApp(tester, container);
        expect(find.text('Connected'), findsOneWidget);
      });

      testWidgets('shows connecting status', (WidgetTester tester) async {
        final container = TestHelpers.createConnectingScenario();
        await pumpApp(tester, container);
        expect(find.text('Connecting...'), findsOneWidget);
      });

      testWidgets('shows disconnected status', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(
          useMockGrpc: false,
          connectionStatus: ConnectionStatus.failed,
        );
        await pumpApp(tester, container);
        expect(find.text('Disconnected'), findsOneWidget);
      });
    });

    group('Message Display', () {
      testWidgets('displays conversation messages', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(
          messages: TestHelpers.createTestConversation(),
        );
        await pumpApp(tester, container);
        
        expect(find.text('Hello, how are you?'), findsOneWidget);
        expect(find.textContaining('I\'m doing well'), findsOneWidget);
        expect(find.text('Can you help me with Flutter testing?'), findsOneWidget);
        expect(find.textContaining('Absolutely!'), findsOneWidget);
      });

      testWidgets('displays error messages with action buttons', (WidgetTester tester) async {
        final container = TestHelpers.createErrorScenario();
        await pumpApp(tester, container);
        
        expect(find.textContaining('Error'), findsWidgets);
        expect(find.text('Enable Mock Mode'), findsWidgets);
        expect(find.text('Retry Connection'), findsWidgets);
      });

      testWidgets('handles empty message list', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(messages: []);
        await pumpApp(tester, container);
        
        expect(find.byType(ListView), findsOneWidget);
        // Should show input but no messages
        expect(find.text('Say something...'), findsOneWidget);
      });
    });

    group('Active Conversation Features', () {
      testWidgets('shows active conversation indicator', (WidgetTester tester) async {
        final container = TestHelpers.createActiveConversationScenario();
        await pumpApp(tester, container);
        
        expect(find.text('Active conversation'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('hides conversation indicator when no active conversation', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(hasActiveConversation: false);
        await pumpApp(tester, container);
        
        expect(find.text('Active conversation'), findsNothing);
        expect(find.byIcon(Icons.refresh), findsNothing);
      });
    });

    group('Debug Features', () {
      testWidgets('shows debug button in debug mode', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(isDebugMode: true);
        await pumpApp(tester, container);
        
        expect(find.byType(Badge), findsOneWidget);
      });

      testWidgets('hides debug button in production mode', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(isDebugMode: false);
        await pumpApp(tester, container);
        
        expect(find.byType(Badge), findsNothing);
      });

      testWidgets('shows correct badge text for mock mode', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(
          isDebugMode: true,
          useMockGrpc: true,
        );
        await pumpApp(tester, container);
        
        expect(find.text('MOCK'), findsOneWidget);
      });

      testWidgets('shows correct badge text for real mode', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(
          isDebugMode: true,
          useMockGrpc: false,
        );
        await pumpApp(tester, container);
        
        expect(find.text('REAL'), findsOneWidget);
      });
    });

    group('Model Selection', () {
      testWidgets('displays model picker dropdown', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer();
        await pumpApp(tester, container);
        
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      });

      testWidgets('shows selected model', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(selectedModel: 'gpt-4o');
        await pumpApp(tester, container);
        
        expect(find.text('gpt-4o'), findsOneWidget);
      });
    });

    group('UI Interaction', () {
      testWidgets('text field accepts input', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer();
        await pumpApp(tester, container);
        
        const testMessage = 'Test message input';
        await tester.enterText(find.byType(TextField), testMessage);
        expect(find.text(testMessage), findsOneWidget);
      });

      testWidgets('send button is present and tappable', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer();
        await pumpApp(tester, container);
        
        final sendButton = find.byIcon(Icons.send);
        expect(sendButton, findsOneWidget);
        
        // Verify it's tappable (doesn't throw)
        await tester.tap(sendButton);
        await tester.pumpAndSettle();
      });

      testWidgets('debug settings dialog opens when debug button tapped', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(isDebugMode: true);
        await pumpApp(tester, container);
        
        // Tap debug button
        await tester.tap(find.byIcon(Icons.offline_bolt));
        await tester.pumpAndSettle();
        
        // Should open debug dialog
        expect(find.text('Debug Settings'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('app is accessible with proper semantics', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer();
        await pumpApp(tester, container);
        
        // Check that key interactive elements have proper semantics
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(IconButton), findsWidgets);
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      });

      testWidgets('messages are selectable', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(
          messages: TestHelpers.createTestConversation(),
        );
        await pumpApp(tester, container);
        
        expect(find.byType(SelectableText), findsWidgets);
      });
    });

    group('Long Content Handling', () {
      testWidgets('handles long conversation', (WidgetTester tester) async {
        final container = TestHelpers.createMockContainer(
          messages: TestHelpers.createLongConversation(),
        );
        await pumpApp(tester, container);
        
        // Should display multiple messages
        expect(find.byType(SelectableText), findsWidgets);
        expect(find.byType(Container), findsWidgets); // Message containers
        
        // ListView should be scrollable
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('handles very long message content', (WidgetTester tester) async {
        final longMessage = 'A' * 1000; // Very long message
        final container = TestHelpers.createMockContainer(
          messages: [
            Message.user(longMessage),
            Message.assistant('Short response'),
          ],
        );
        await pumpApp(tester, container);
        
        expect(find.textContaining('A'), findsOneWidget);
        expect(find.text('Short response'), findsOneWidget);
      });
    });
  });
}
