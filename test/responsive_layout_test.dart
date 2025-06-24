import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/ui/home_page.dart';
import 'package:ello_ai/src/ui/components/app_sidebar.dart';
import 'package:ello_ai/src/core/dependencies.dart';

void main() {
  group('Responsive Layout Tests', () {
    ProviderContainer makeMockedContainer() {
      return ProviderContainer(overrides: [
        chatHistoryProvider.overrideWith((ref) => ChatHistoryNotifier()),
        connectionStatusProvider
            .overrideWith((ref) => ConnectionStatusNotifier()..setConnected()),
        useMockGrpcProvider.overrideWith((ref) => MockGrpcNotifier()),
        hasActiveConversationProvider.overrideWith((ref) => false),
        initConnectionStatusProvider.overrideWith((ref) => AsyncValue.data(null)),
      ]);
    }

    testWidgets('Wide screen should show two-pane layout', (WidgetTester tester) async {
      // Set a wide screen size (1200x800)
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: makeMockedContainer(),
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show sidebar in wide screen
      expect(find.byType(AppSidebar), findsOneWidget);
      expect(find.byType(Row), findsWidgets); // Row layout for two-pane
    });

    testWidgets('Narrow screen should show single-pane layout with drawer', (WidgetTester tester) async {
      // Set a narrow screen size (400x800)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: makeMockedContainer(),
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show app bar in narrow screen
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('Chat input should be present in all layouts', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: makeMockedContainer(),
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find text field for input
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Say something...'), findsOneWidget);

      // Should find send button
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('Message constraints should be responsive', (WidgetTester tester) async {
      // Add some test messages
      final container = makeMockedContainer();
      container.read(chatHistoryProvider.notifier).addUserMessage('Test message');
      container.read(chatHistoryProvider.notifier).addAssistantMessage('Response message');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find message containers
      expect(find.text('Test message'), findsOneWidget);
      expect(find.text('Response message'), findsOneWidget);
    });

    // Clean up
    tearDown(() {
      tester.view.resetPhysicalSize();
    });
  });
}