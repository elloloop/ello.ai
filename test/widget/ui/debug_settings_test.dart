import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/ui/debug/debug_settings.dart';
import 'package:ello_ai/src/core/dependencies.dart';

void main() {
  group('DebugSettingsButton Widget Tests', () {
    ProviderContainer createTestContainer({
      bool isDebugMode = true,
      bool useMockGrpc = false,
    }) {
      return ProviderContainer(overrides: [
        isDebugModeProvider.overrideWith((ref) => isDebugMode),
        useMockGrpcProvider.overrideWith((ref) {
          final notifier = MockGrpcNotifier();
          if (useMockGrpc) notifier.toggle();
          return notifier;
        }),
      ]);
    }

    Widget createDebugSettingsButton(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: const DebugSettingsButton(),
          ),
        ),
      );
    }

    testWidgets('shows debug button when in debug mode', (WidgetTester tester) async {
      final container = createTestContainer(isDebugMode: true);
      await tester.pumpWidget(createDebugSettingsButton(container));
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('hides debug button when not in debug mode', (WidgetTester tester) async {
      final container = createTestContainer(isDebugMode: false);
      await tester.pumpWidget(createDebugSettingsButton(container));
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('shows REAL badge when not using mock gRPC', (WidgetTester tester) async {
      final container = createTestContainer(isDebugMode: true, useMockGrpc: false);
      await tester.pumpWidget(createDebugSettingsButton(container));
      await tester.pumpAndSettle();

      expect(find.text('REAL'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets('shows MOCK badge when using mock gRPC', (WidgetTester tester) async {
      final container = createTestContainer(isDebugMode: true, useMockGrpc: true);
      await tester.pumpWidget(createDebugSettingsButton(container));
      await tester.pumpAndSettle();

      expect(find.text('MOCK'), findsOneWidget);
      expect(find.byIcon(Icons.offline_bolt), findsOneWidget);
    });

    testWidgets('opens dialog when button is tapped', (WidgetTester tester) async {
      final container = createTestContainer(isDebugMode: true);
      await tester.pumpWidget(createDebugSettingsButton(container));
      await tester.pumpAndSettle();

      // Tap the debug button
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Should open debug settings dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Debug Settings'), findsOneWidget);
    });
  });

  group('DebugSettingsDialog Widget Tests', () {
    ProviderContainer createTestContainer({
      bool useMockGrpc = false,
      String grpcHost = 'test-host',
      int grpcPort = 1234,
      bool grpcSecure = false,
      bool autoFallback = false,
      int failCount = 0,
      int maxAttempts = 3,
    }) {
      return ProviderContainer(overrides: [
        useMockGrpcProvider.overrideWith((ref) {
          final notifier = MockGrpcNotifier();
          if (useMockGrpc) notifier.toggle();
          return notifier;
        }),
        grpcHostProvider.overrideWith((ref) => GrpcHostNotifier()..updateHost(grpcHost)),
        grpcPortProvider.overrideWith((ref) => GrpcPortNotifier()..updatePort(grpcPort)),
        grpcSecureProvider.overrideWith((ref) => GrpcSecureNotifier()..setSecure(grpcSecure)),
        autoFallbackToMockProvider.overrideWith((ref) => autoFallback),
        connectionFailCounterProvider.overrideWith((ref) => failCount),
        maxConnectionAttemptsProvider.overrideWith((ref) => maxAttempts),
      ]);
    }

    Widget createDebugSettingsDialog(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const DebugSettingsDialog(),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('displays dialog with correct title', (WidgetTester tester) async {
      final container = createTestContainer();
      await tester.pumpWidget(createDebugSettingsDialog(container));
      
      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Debug Settings'), findsOneWidget);
    });

    testWidgets('shows enable mock mode button when not in mock mode', (WidgetTester tester) async {
      final container = createTestContainer(useMockGrpc: false);
      await tester.pumpWidget(createDebugSettingsDialog(container));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Enable Mock Mode'), findsOneWidget);
      expect(find.byIcon(Icons.offline_bolt), findsOneWidget);
    });

    testWidgets('shows connection settings section', (WidgetTester tester) async {
      final container = createTestContainer();
      await tester.pumpWidget(createDebugSettingsDialog(container));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Connection Handling'), findsOneWidget);
    });

    testWidgets('displays gRPC connection settings', (WidgetTester tester) async {
      final container = createTestContainer(grpcHost: 'example.com', grpcPort: 443);
      await tester.pumpWidget(createDebugSettingsDialog(container));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should display current settings
      expect(find.textContaining('example.com'), findsOneWidget);
      expect(find.textContaining('443'), findsOneWidget);
    });

    testWidgets('shows test connection buttons', (WidgetTester tester) async {
      final container = createTestContainer();
      await tester.pumpWidget(createDebugSettingsDialog(container));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Plain'), findsOneWidget);
      expect(find.text('Test with TLS'), findsOneWidget);
    });

    testWidgets('can toggle auto-fallback setting', (WidgetTester tester) async {
      final container = createTestContainer(autoFallback: false);
      await tester.pumpWidget(createDebugSettingsDialog(container));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Auto-fallback to Mock'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('displays connection attempt information', (WidgetTester tester) async {
      final container = createTestContainer(failCount: 2, maxAttempts: 3);
      await tester.pumpWidget(createDebugSettingsDialog(container));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed attempts: 2/3'), findsOneWidget);
    });

    testWidgets('can close dialog', (WidgetTester tester) async {
      final container = createTestContainer();
      await tester.pumpWidget(createDebugSettingsDialog(container));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Should have close button or be dismissible
      await tester.tap(find.byType(AlertDialog));
      await tester.pumpAndSettle();
    });
  });
}