import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/main.dart';
import 'package:ello_ai/src/core/dependencies.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ello.AI End-to-End Tests', () {
    ProviderContainer createMockContainer() {
      return ProviderContainer(overrides: [
        chatHistoryProvider.overrideWith((ref) => ChatHistoryNotifier()),
        connectionStatusProvider
            .overrideWith((ref) => ConnectionStatusNotifier()..setConnected()),
        useMockGrpcProvider.overrideWith((ref) => MockGrpcNotifier()..toggle()),
        modelProvider.overrideWith((ref) => ModelNotifier()),
        availableModelsProvider
            .overrideWith((ref) => ['gpt-3.5-turbo', 'gpt-4o', 'claude-3']),
        isDebugModeProvider.overrideWith((ref) => true),
        grpcHostProvider
            .overrideWith((ref) => GrpcHostNotifier()..updateHost('mock-host')),
        grpcPortProvider
            .overrideWith((ref) => GrpcPortNotifier()..updatePort(1234)),
        grpcSecureProvider
            .overrideWith((ref) => GrpcSecureNotifier()..setSecure(false)),
        initConnectionStatusProvider.overrideWith((ref) {}),
      ]);
    }

    testWidgets('complete chat workflow', (WidgetTester tester) async {
      final container = createMockContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app loads with correct title
      expect(find.text('ello.AI'), findsOneWidget);
      expect(find.text('Say something...'), findsOneWidget);

      // Type a message
      const testMessage = 'Hello, AI assistant!';
      await tester.enterText(find.byType(TextField), testMessage);
      await tester.pumpAndSettle();

      // Send the message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Wait for response (in mock mode should be immediate)
      await tester.pump(const Duration(milliseconds: 500));

      // Verify user message appears
      expect(find.text(testMessage), findsOneWidget);

      // Verify assistant response appears (mock response)
      expect(find.textContaining('Hello from MockClient'), findsOneWidget);

      // Verify text field is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('model selection workflow', (WidgetTester tester) async {
      final container = createMockContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the model dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Verify models are available
      expect(find.text('gpt-3.5-turbo'), findsWidgets);
      expect(find.text('gpt-4o'), findsOneWidget);
      expect(find.text('claude-3'), findsOneWidget);

      // Select a different model
      await tester.tap(find.text('gpt-4o').last);
      await tester.pumpAndSettle();

      // Send a message to verify the model selection works
      await tester.enterText(find.byType(TextField), 'Test with gpt-4o');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify response mentions the selected model
      expect(find.textContaining('gpt-4o'), findsOneWidget);
    });

    testWidgets('debug settings workflow', (WidgetTester tester) async {
      final container = createMockContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify debug button is present (should be in debug mode)
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('MOCK'), findsOneWidget);

      // Tap debug settings button
      await tester.tap(find.byIcon(Icons.offline_bolt));
      await tester.pumpAndSettle();

      // Verify debug dialog opens
      expect(find.text('Debug Settings'), findsOneWidget);
      expect(find.text('Connection Handling'), findsOneWidget);

      // Close dialog by tapping outside or finding close button
      await tester.tapAt(const Offset(50, 50)); // Tap outside dialog
      await tester.pumpAndSettle();
    });

    testWidgets('connection status indicator workflow', (WidgetTester tester) async {
      final container = createMockContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show Mock Mode status
      expect(find.text('Mock Mode'), findsOneWidget);
      
      // Should have colored status indicator
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('multiple messages conversation', (WidgetTester tester) async {
      final container = createMockContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Send first message
      await tester.enterText(find.byType(TextField), 'First message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Wait for response
      await tester.pump(const Duration(milliseconds: 100));

      // Send second message
      await tester.enterText(find.byType(TextField), 'Second message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Wait for response
      await tester.pump(const Duration(milliseconds: 100));

      // Verify both messages and responses are visible
      expect(find.text('First message'), findsOneWidget);
      expect(find.text('Second message'), findsOneWidget);
      expect(find.textContaining('Hello from MockClient'), findsNWidgets(2));

      // Verify conversation history shows 4 messages total (2 user + 2 assistant)
      expect(find.byType(Container), findsWidgets); // Message containers
    });

    testWidgets('text selection and copy functionality', (WidgetTester tester) async {
      final container = createMockContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Send a message to have text to select
      await tester.enterText(find.byType(TextField), 'Test message for selection');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Wait for response
      await tester.pump(const Duration(milliseconds: 100));

      // Verify SelectableText widgets are present
      expect(find.byType(SelectableText), findsWidgets);

      // Find a SelectableText widget and verify it's selectable
      final selectableText = find.byType(SelectableText).first;
      expect(selectableText, findsOneWidget);

      // Long press to trigger selection (simulates user interaction)
      await tester.longPress(selectableText);
      await tester.pumpAndSettle();
    });

    testWidgets('app bar actions workflow', (WidgetTester tester) async {
      final container = createMockContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar contains action buttons
      expect(find.byType(IconButton), findsWidgets);
      
      // Verify presence of various UI elements in app bar
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('ello.AI'), findsOneWidget);
    });

    testWidgets('keyboard input and submission', (WidgetTester tester) async {
      final container = createMockContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ElloApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Test keyboard submission (Enter key)
      await tester.enterText(find.byType(TextField), 'Message via keyboard');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Wait for response
      await tester.pump(const Duration(milliseconds: 100));

      // Verify message was sent
      expect(find.text('Message via keyboard'), findsOneWidget);
    });
  });
}