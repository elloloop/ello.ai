#include "system_theme_channel.h"
#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>

// Method channel implementation for Linux
static FlMethodChannel* system_theme_channel = nullptr;

// Get system theme preference using GSettings (GNOME) or fallback
static gboolean get_system_theme_preference() {
  // Try to get theme from GSettings (GNOME)
  g_autoptr(GSettings) settings = g_settings_new("org.gnome.desktop.interface");
  if (settings) {
    g_autofree gchar* theme_name = g_settings_get_string(settings, "gtk-theme");
    if (theme_name) {
      // Simple heuristic: if theme contains "dark", it's dark mode
      return !g_str_has_suffix(theme_name, "-dark") && !g_strstr_len(theme_name, -1, "Dark");
    }
  }
  
  // Fallback: assume light mode
  return TRUE;
}

// Method call handler
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  
  if (strcmp(method, "getSystemThemeMode") == 0) {
    gboolean is_light_mode = get_system_theme_preference();
    g_autoptr(FlValue) result = fl_value_new_bool(is_light_mode);
    fl_method_call_respond(method_call, result, nullptr);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

void setup_system_theme_channel(FlView* view) {
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  
  system_theme_channel = fl_method_channel_new(messenger, "ello.ai/system_theme",
                                                FL_METHOD_CODEC(fl_standard_method_codec_new()));
  
  fl_method_channel_set_method_call_handler(system_theme_channel, method_call_cb,
                                            nullptr, nullptr);
}