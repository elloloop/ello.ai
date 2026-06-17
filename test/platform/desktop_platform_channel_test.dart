import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/platform/desktop_platform_channel.dart';

void main() {
  group('DesktopPlatformChannel', () {
    test('getPlatformInfo returns valid data', () async {
      final info = await DesktopPlatformChannel.getPlatformInfo();
      
      expect(info, isA<Map<String, dynamic>>());
      expect(info.containsKey('platform'), true);
      
      // Should contain basic platform info even if channel is not available
      final platform = info['platform'] as String;
      expect(['macos', 'windows', 'linux'].contains(platform), true);
    });

    test('setWindowTitle handles gracefully', () async {
      // Should not throw even if platform channel is not available
      final result = await DesktopPlatformChannel.setWindowTitle('Test Title');
      expect(result, isA<bool>());
    });

    test('getSystemTheme returns valid theme', () async {
      final theme = await DesktopPlatformChannel.getSystemTheme();
      expect(['light', 'dark'].contains(theme), true);
    });

    test('getAppVersion returns valid data', () async {
      final version = await DesktopPlatformChannel.getAppVersion();
      expect(version, isA<Map<String, String>>());
    });

    test('isRunningAsAdmin returns boolean', () async {
      final isAdmin = await DesktopPlatformChannel.isRunningAsAdmin();
      expect(isAdmin, isA<bool>());
    });

    test('notification methods handle gracefully', () async {
      final hasPermission = await DesktopPlatformChannel.requestNotificationPermission();
      expect(hasPermission, isA<bool>());

      final showResult = await DesktopPlatformChannel.showNotification(
        title: 'Test',
        body: 'Test notification',
      );
      expect(showResult, isA<bool>());
    });

    test('tray methods handle gracefully', () async {
      final minimizeResult = await DesktopPlatformChannel.minimizeToTray();
      expect(minimizeResult, isA<bool>());

      final showResult = await DesktopPlatformChannel.showFromTray();
      expect(showResult, isA<bool>());
    });
  });
}