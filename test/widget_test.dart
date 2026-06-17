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

void main() {
  group('ElloApp Widget Tests', () {
    ProviderContainer makeMockedContainer() {
      return ProviderContainer(overrides: [
        chatHistoryProvider.overrideWith((ref) => ChatHistoryNotifier()),
        connectionStatusProvider
            .overrideWith((ref) => ConnectionStatusNotifier()..setConnected()),
        useMockGrpcProvider.overrideWith((ref) => MockGrpcNotifier()..toggle()),
        modelProvider.overrideWith((ref) => ModelNotifier()),
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
        conversationListProvider.overrideWith((ref) => ConversationListNotifier()),
        activeConversationIdProvider.overrideWith((ref) => null),
        conversationProvider.overrideWith((ref) => ConversationController(ref)),
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

    testWidgets('App has conversation list sidebar', (WidgetTester tester) async {
      final container = makeMockedContainer();
      await pumpApp(tester, container);
      expect(find.text('New Chat'), findsOneWidget);
      expect(find.text('No conversations yet.\nStart a new chat!'), findsOneWidget);
    });

    testWidgets('Chat messages list view is present',
        (WidgetTester tester) async {
      final container = makeMockedContainer();
      await pumpApp(tester, container);
      expect(find.byType(ListView), findsWidgets);
    });
  });
}
