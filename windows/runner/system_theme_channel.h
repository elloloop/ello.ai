#ifndef SYSTEM_THEME_CHANNEL_H_
#define SYSTEM_THEME_CHANNEL_H_

#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <memory>

class SystemThemeChannel {
 public:
  explicit SystemThemeChannel(flutter::FlutterEngine* engine);

  void NotifyThemeChanged();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::FlutterEngine* engine_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // SYSTEM_THEME_CHANNEL_H_