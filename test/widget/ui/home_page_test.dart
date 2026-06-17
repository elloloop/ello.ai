import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/ui/home_page.dart';
import 'package:ello_ai/src/core/dependencies.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('HomePage Widget Tests', () {
    ProviderContainer createTestContainer({
      List<Message> messages = const [],
      ConnectionStatus connectionStatus = ConnectionStatus.connected,
      bool useMockGrpc = true,
      bool hasActiveConversation = false,
    }) {
      return ProviderContainer(overrides: [
        chatHistoryProvider.overrideWith((ref) {
          final notifier = ChatHistoryNotifier();
          for (final message in messages) {
            if (message.isUser) {
              notifier.addUserMessage(message.content);
            } else {
              notifier.addAssistantMessage(message.content);
            }
          }
          return notifier;
        }),
        connectionStatusProvider.overrideWith((ref) {
          final notifier = ConnectionStatusNotifier();
          switch (connectionStatus) {
            case ConnectionStatus.connected:
              notifier.setConnected();
              break;
            case ConnectionStatus.connecting:
              notifier.setConnecting();
              break;
            case ConnectionStatus.failed:
              notifier.setFailed();
              break;
          }
          return notifier;
        }),
        useMockGrpcProvider.overrideWith((ref) {
          final notifier = MockGrpcNotifier();
          if (useMockGrpc) notifier.toggle();
          return notifier;
        }),
        modelProvider.overrideWith((ref) => ModelNotifier()),
        availableModelsProvider.overrideWith((ref) => ['gpt-3.5-turbo', 'gpt-4o']),
        isDebugModeProvider.overrideWith((ref) => true),
        grpcHostProvider.overrideWith((ref) => GrpcHostNotifier()..updateHost('test-host')),
        grpcPortProvider.overrideWith((ref) => GrpcPortNotifier()..updatePort(1234)),
        grpcSecureProvider.overrideWith((ref) => GrpcSecureNotifier()..setSecure(false)),
        initConnectionStatusProvider.overrideWith((ref) {}),
        hasActiveConversationProvider.overrideWith((ref) => hasActiveConversation),
      ]);
    }

    Widget createHomePage(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: const HomePage(),
        ),
      );
    }

    group('Basic Structure', () {
      testWidgets('displays app bar with correct title', (WidgetTester tester) async {
        final container = createTestContainer();
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('ello.AI'), findsOneWidget);
      });

      testWidgets('shows active conversation indicator when conversation is active', (WidgetTester tester) async {
        final container = createTestContainer(hasActiveConversation: true);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Active conversation'), findsOneWidget);
      });

      testWidgets('hides active conversation indicator when no conversation', (WidgetTester tester) async {
        final container = createTestContainer(hasActiveConversation: false);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Active conversation'), findsNothing);
      });

      testWidgets('displays reset conversation button when conversation is active', (WidgetTester tester) async {
        final container = createTestContainer(hasActiveConversation: true);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('displays basic UI components', (WidgetTester tester) async {
        final container = createTestContainer();
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.send), findsOneWidget);
        expect(find.text('Say something...'), findsOneWidget);
      });
    });

    group('Connection Status Display', () {
      testWidgets('shows connected status correctly', (WidgetTester tester) async {
        final container = createTestContainer(
          connectionStatus: ConnectionStatus.connected,
          useMockGrpc: false,
        );
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Connected'), findsOneWidget);
      });

      testWidgets('shows connecting status correctly', (WidgetTester tester) async {
        final container = createTestContainer(
          connectionStatus: ConnectionStatus.connecting,
          useMockGrpc: false,
        );
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Connecting...'), findsOneWidget);
      });

      testWidgets('shows disconnected status correctly', (WidgetTester tester) async {
        final container = createTestContainer(
          connectionStatus: ConnectionStatus.failed,
          useMockGrpc: false,
        );
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Disconnected'), findsOneWidget);
      });

      testWidgets('shows mock mode status correctly', (WidgetTester tester) async {
        final container = createTestContainer(useMockGrpc: true);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Mock Mode'), findsOneWidget);
      });
    });

    group('Message Display', () {
      testWidgets('displays user messages correctly', (WidgetTester tester) async {
        final messages = [Message.user('Hello, this is a user message')];
        final container = createTestContainer(messages: messages);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Hello, this is a user message'), findsOneWidget);
      });

      testWidgets('displays assistant messages correctly', (WidgetTester tester) async {
        final messages = [Message.assistant('Hello, this is an assistant response')];
        final container = createTestContainer(messages: messages);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Hello, this is an assistant response'), findsOneWidget);
      });

      testWidgets('displays multiple messages in correct order', (WidgetTester tester) async {
        final messages = [
          Message.user('First user message'),
          Message.assistant('First assistant response'),
          Message.user('Second user message'),
          Message.assistant('Second assistant response'),
        ];
        final container = createTestContainer(messages: messages);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('First user message'), findsOneWidget);
        expect(find.text('First assistant response'), findsOneWidget);
        expect(find.text('Second user message'), findsOneWidget);
        expect(find.text('Second assistant response'), findsOneWidget);
      });

      testWidgets('shows empty list when no messages', (WidgetTester tester) async {
        final container = createTestContainer(messages: []);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
        // No message text should be found
        expect(find.text('Hello'), findsNothing);
      });
    });

    group('Error Handling UI', () {
      testWidgets('shows mock mode button for error messages', (WidgetTester tester) async {
        final messages = [Message.assistant('Error: Connection failed')];
        final container = createTestContainer(messages: messages, useMockGrpc: false);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Enable Mock Mode'), findsOneWidget);
        expect(find.text('Retry Connection'), findsOneWidget);
      });

      testWidgets('does not show error buttons for normal messages', (WidgetTester tester) async {
        final messages = [Message.assistant('This is a normal response')];
        final container = createTestContainer(messages: messages);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Enable Mock Mode'), findsNothing);
        expect(find.text('Retry Connection'), findsNothing);
      });

      testWidgets('mock mode button shows appropriate text when already in mock mode', (WidgetTester tester) async {
        final messages = [Message.assistant('Error: Connection failed')];
        final container = createTestContainer(messages: messages, useMockGrpc: true);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        // Should still show the button for error messages
        expect(find.text('Enable Mock Mode'), findsOneWidget);
      });
    });

    group('Chat Input', () {
      testWidgets('text field accepts input', (WidgetTester tester) async {
        final container = createTestContainer();
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        await tester.enterText(textField, 'Test message');
        expect(find.text('Test message'), findsOneWidget);
      });

      testWidgets('send button is present and tappable', (WidgetTester tester) async {
        final container = createTestContainer();
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        final sendButton = find.byIcon(Icons.send);
        expect(sendButton, findsOneWidget);

        // Verify it's tappable (doesn't throw)
        await tester.tap(sendButton);
        await tester.pumpAndSettle();
      });

      testWidgets('text field shows correct hint', (WidgetTester tester) async {
        final container = createTestContainer();
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        expect(find.text('Say something...'), findsOneWidget);
      });
    });

    group('Message Containers and Styling', () {
      testWidgets('messages are contained in proper widgets', (WidgetTester tester) async {
        final messages = [
          Message.user('User message'),
          Message.assistant('Assistant message')
        ];
        final container = createTestContainer(messages: messages);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        // Should have containers for messages
        expect(find.byType(Container), findsWidgets);
        expect(find.byType(SelectableText), findsNWidgets(2));
      });

      testWidgets('messages are selectable', (WidgetTester tester) async {
        final messages = [Message.user('Selectable text')];
        final container = createTestContainer(messages: messages);
        await tester.pumpWidget(createHomePage(container));
        await tester.pumpAndSettle();

        final selectableText = find.byType(SelectableText);
        expect(selectableText, findsOneWidget);

        // Verify the text content
        final widget = tester.widget<SelectableText>(selectableText);
        expect(widget.data, equals('Selectable text'));
        expect(widget.enableInteractiveSelection, isTrue);
      });
    });
  });
}