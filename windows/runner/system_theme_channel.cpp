#include "system_theme_channel.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <dwmapi.h>

namespace {

const std::string kChannelName = "ello.ai/system_theme";

/// Registry key for app theme preference.
constexpr const wchar_t kGetPreferredBrightnessRegKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
constexpr const wchar_t kGetPreferredBrightnessRegValue[] = L"AppsUseLightTheme";

/// Get the current system theme preference
bool GetSystemThemePreference() {
  DWORD light_mode;
  DWORD light_mode_size = sizeof(light_mode);
  LSTATUS result = RegGetValue(HKEY_CURRENT_USER, kGetPreferredBrightnessRegKey,
                               kGetPreferredBrightnessRegValue,
                               RRF_RT_REG_DWORD, nullptr, &light_mode,
                               &light_mode_size);

  if (result == ERROR_SUCCESS) {
    return light_mode != 0; // Returns true for light mode, false for dark mode
  }
  return true; // Default to light mode if registry read fails
}

}

SystemThemeChannel::SystemThemeChannel(flutter::FlutterEngine* engine)
    : engine_(engine) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine_->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        HandleMethodCall(call, std::move(result));
      });

  channel_ = std::move(channel);
}

void SystemThemeChannel::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getSystemThemeMode") == 0) {
    bool is_light_mode = GetSystemThemePreference();
    result->Success(flutter::EncodableValue(is_light_mode));
  } else {
    result->NotImplemented();
  }
}

void SystemThemeChannel::NotifyThemeChanged() {
  if (channel_) {
    bool is_light_mode = GetSystemThemePreference();
    bool is_dark_mode = !is_light_mode;
    
    channel_->InvokeMethod(
        "onSystemThemeChanged",
        std::make_unique<flutter::EncodableValue>(flutter::EncodableValue(is_dark_mode)));
  }
}