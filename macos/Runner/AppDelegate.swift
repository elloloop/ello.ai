import Cocoa
import FlutterMacOS
import UserNotifications

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
    
    // Set up platform channel for desktop-specific functionality
    setupPlatformChannel()
  }

  private func setupPlatformChannel() {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "ello.ai/desktop",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getPlatformInfo":
        result([
          "platform": "macos",
          "version": ProcessInfo.processInfo.operatingSystemVersionString,
          "arch": self.getArchitecture()
        ])
      
      case "setWindowTitle":
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String {
          DispatchQueue.main.async {
            self.mainFlutterWindow?.title = title
          }
          result(true)
        } else {
          result(false)
        }
      
      case "getSystemTheme":
        let appearance = NSApp.effectiveAppearance
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        result(isDark ? "dark" : "light")
      
      case "getAppVersion":
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        result([
          "version": version,
          "build": build,
          "bundleId": Bundle.main.bundleIdentifier ?? "Unknown"
        ])
      
      case "isRunningAsAdmin":
        result(getuid() == 0)
      
      case "requestNotificationPermission":
        self.requestNotificationPermission { granted in
          result(granted)
        }
      
      case "showNotification":
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String,
           let body = args["body"] as? String {
          self.showNotification(title: title, body: body)
          result(true)
        } else {
          result(false)
        }
      
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func getArchitecture() -> String {
    var size = 0
    sysctlbyname("hw.target", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.target", &machine, &size, nil, 0)
    return String(cString: machine)
  }

  private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      completion(granted)
    }
  }

  private func showNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )

    UNUserNotificationCenter.current().add(request)
  }
}
