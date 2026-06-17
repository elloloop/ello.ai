#include "flutter_window.h"

#include <optional>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Set up platform channel for desktop-specific functionality
  SetupPlatformChannel();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::SetupPlatformChannel() {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "ello.ai/desktop",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("getPlatformInfo") == 0) {
          flutter::EncodableMap info;
          info[flutter::EncodableValue("platform")] = flutter::EncodableValue("windows");
          
          // Get Windows version
          OSVERSIONINFOW version_info = {};
          version_info.dwOSVersionInfoSize = sizeof(OSVERSIONINFOW);
          if (GetVersionExW(&version_info)) {
            std::string version_string = std::to_string(version_info.dwMajorVersion) + "." +
                                       std::to_string(version_info.dwMinorVersion) + "." +
                                       std::to_string(version_info.dwBuildNumber);
            info[flutter::EncodableValue("version")] = flutter::EncodableValue(version_string);
          }
          
          info[flutter::EncodableValue("arch")] = flutter::EncodableValue("x64");
          result->Success(flutter::EncodableValue(info));
        }
        else if (call.method_name().compare("setWindowTitle") == 0) {
          const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments) {
            auto title_it = arguments->find(flutter::EncodableValue("title"));
            if (title_it != arguments->end()) {
              const auto* title = std::get_if<std::string>(&title_it->second);
              if (title) {
                std::wstring wide_title = std::wstring(title->begin(), title->end());
                SetWindowTextW(GetHandle(), wide_title.c_str());
                result->Success(flutter::EncodableValue(true));
                return;
              }
            }
          }
          result->Success(flutter::EncodableValue(false));
        }
        else if (call.method_name().compare("getSystemTheme") == 0) {
          // Check if Windows is in dark mode
          DWORD value = 0;
          DWORD value_size = sizeof(value);
          HKEY key;
          if (RegOpenKeyExW(HKEY_CURRENT_USER, 
              L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
              0, KEY_READ, &key) == ERROR_SUCCESS) {
            if (RegQueryValueExW(key, L"AppsUseLightTheme", nullptr, nullptr,
                reinterpret_cast<LPBYTE>(&value), &value_size) == ERROR_SUCCESS) {
              result->Success(flutter::EncodableValue(value == 0 ? "dark" : "light"));
            } else {
              result->Success(flutter::EncodableValue("light"));
            }
            RegCloseKey(key);
          } else {
            result->Success(flutter::EncodableValue("light"));
          }
        }
        else if (call.method_name().compare("getAppVersion") == 0) {
          flutter::EncodableMap version_info;
          
          // Get file version information
          wchar_t exe_path[MAX_PATH];
          GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
          
          DWORD version_handle = 0;
          DWORD version_size = GetFileVersionInfoSizeW(exe_path, &version_handle);
          if (version_size > 0) {
            std::vector<BYTE> version_data(version_size);
            if (GetFileVersionInfoW(exe_path, version_handle, version_size, version_data.data())) {
              VS_FIXEDFILEINFO* file_info = nullptr;
              UINT len = 0;
              if (VerQueryValueW(version_data.data(), L"\\", reinterpret_cast<LPVOID*>(&file_info), &len)) {
                std::string version = std::to_string(HIWORD(file_info->dwFileVersionMS)) + "." +
                                    std::to_string(LOWORD(file_info->dwFileVersionMS)) + "." +
                                    std::to_string(HIWORD(file_info->dwFileVersionLS)) + "." +
                                    std::to_string(LOWORD(file_info->dwFileVersionLS));
                version_info[flutter::EncodableValue("version")] = flutter::EncodableValue(version);
              }
            }
          }
          
          version_info[flutter::EncodableValue("platform")] = flutter::EncodableValue("Windows");
          result->Success(flutter::EncodableValue(version_info));
        }
        else if (call.method_name().compare("isRunningAsAdmin") == 0) {
          BOOL is_admin = FALSE;
          PSID admin_group = nullptr;
          SID_IDENTIFIER_AUTHORITY nt_authority = SECURITY_NT_AUTHORITY;
          
          if (AllocateAndInitializeSid(&nt_authority, 2, SECURITY_BUILTIN_DOMAIN_RID,
              DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, &admin_group)) {
            CheckTokenMembership(nullptr, admin_group, &is_admin);
            FreeSid(admin_group);
          }
          
          result->Success(flutter::EncodableValue(is_admin == TRUE));
        }
        else {
          result->NotImplemented();
        }
      });

  platform_channel_ = std::move(channel);
}
