import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // Register system theme channel
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "ello.ai/system_theme", binaryMessenger: controller.engine.binaryMessenger)
      
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "getSystemThemeMode":
          let appearance = NSApp.effectiveAppearance
          let isLightMode = appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
          result(isLightMode)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      
      // Listen for system appearance changes
      DistributedNotificationCenter.default.addObserver(
        forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
        object: nil,
        queue: .main
      ) { _ in
        let appearance = NSApp.effectiveAppearance
        let isDarkMode = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        channel.invokeMethod("onSystemThemeChanged", arguments: isDarkMode)
      }
    }
  }
}
