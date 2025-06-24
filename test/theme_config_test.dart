import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/config/app_config.dart';
import 'package:ello_ai/src/ui/components/theme_toggle_button.dart';

void main() {
  group('Theme Configuration Tests', () {
    test('AppConfig should have correct default values', () {
      const config = AppConfig();
      
      expect(config.themeMode, ThemeMode.system);
      expect(config.followSystemTheme, true);
    });

    test('AppConfig toJson and fromJson should work correctly', () {
      const originalConfig = AppConfig(
        themeMode: ThemeMode.dark,
        followSystemTheme: false,
      );
      
      final json = originalConfig.toJson();
      final restoredConfig = AppConfig.fromJson(json);
      
      expect(restoredConfig.themeMode, originalConfig.themeMode);
      expect(restoredConfig.followSystemTheme, originalConfig.followSystemTheme);
    });

    test('AppConfig copyWith should work correctly', () {
      const config = AppConfig();
      
      final updatedConfig = config.copyWith(
        themeMode: ThemeMode.light,
        followSystemTheme: false,
      );
      
      expect(updatedConfig.themeMode, ThemeMode.light);
      expect(updatedConfig.followSystemTheme, false);
    });

    testWidgets('ThemeToggleButton should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: const ThemeToggleButton(),
            ),
          ),
        ),
      );

      // Should find the theme toggle button
      expect(find.byType(PopupMenuButton<ThemeMode>), findsOneWidget);
    });

    testWidgets('ThemeToggleButton should show menu on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: const ThemeToggleButton(),
            ),
          ),
        ),
      );

      // Tap the theme toggle button
      await tester.tap(find.byType(PopupMenuButton<ThemeMode>));
      await tester.pumpAndSettle();

      // Should show the popup menu with theme options
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });
  });
}