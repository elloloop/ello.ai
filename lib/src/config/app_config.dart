import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../services/system_theme_service.dart';

/// Application configuration model
class AppConfig {
  final ThemeMode themeMode;
  final bool followSystemTheme;

  const AppConfig({
    this.themeMode = ThemeMode.system,
    this.followSystemTheme = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'followSystemTheme': followSystemTheme,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      followSystemTheme: json['followSystemTheme'] ?? true,
    );
  }

  AppConfig copyWith({
    ThemeMode? themeMode,
    bool? followSystemTheme,
  }) {
    return AppConfig(
      themeMode: themeMode ?? this.themeMode,
      followSystemTheme: followSystemTheme ?? this.followSystemTheme,
    );
  }
}

/// App configuration notifier
class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier() : super(const AppConfig()) {
    _loadConfig();
    _initializeSystemThemeListener();
  }

  late final String _configPath;

  Future<void> _loadConfig() async {
    try {
      _configPath = await _getConfigPath();
      final configFile = File(_configPath);
      
      if (await configFile.exists()) {
        final jsonString = await configFile.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        state = AppConfig.fromJson(jsonData);
      }
    } catch (e) {
      // If loading fails, keep the default configuration
      print('Failed to load config: $e');
    }
  }

  Future<void> _saveConfig() async {
    try {
      final configFile = File(_configPath);
      
      // Ensure the directory exists
      await configFile.parent.create(recursive: true);
      
      final jsonString = jsonEncode(state.toJson());
      await configFile.writeAsString(jsonString);
    } catch (e) {
      print('Failed to save config: $e');
    }
  }

  Future<String> _getConfigPath() async {
    final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    final configDir = path.join(homeDir, '.config', 'ello');
    return path.join(configDir, 'config.json');
  }

  void _initializeSystemThemeListener() {
    // Set up listener for system theme changes
    SystemThemeService.listenToSystemThemeChanges((ThemeMode systemMode) {
      // Only update if user is following system theme
      if (state.followSystemTheme && state.themeMode == ThemeMode.system) {
        // The state doesn't need to change, but we can trigger a rebuild
        // by temporarily setting and then resetting the same value
        final currentState = state;
        state = currentState.copyWith();
      }
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(
      themeMode: mode,
      followSystemTheme: mode == ThemeMode.system,
    );
    await _saveConfig();
  }

  Future<void> setFollowSystemTheme(bool follow) async {
    state = state.copyWith(
      followSystemTheme: follow,
      themeMode: follow ? ThemeMode.system : state.themeMode,
    );
    await _saveConfig();
  }

  /// Get the effective theme mode for the current system
  Future<ThemeMode> getEffectiveThemeMode() async {
    if (state.themeMode == ThemeMode.system) {
      try {
        return await SystemThemeService.getSystemThemeMode();
      } catch (e) {
        print('Failed to get system theme: $e');
        return ThemeMode.system;
      }
    }
    return state.themeMode;
  }
}

/// App configuration provider
final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier();
});