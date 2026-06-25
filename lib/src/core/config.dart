import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String devBaseUrl = 'http://localhost:8080';
  static const String prodBaseUrl = 'https://api.cookest.app';
  static const String keyCustomServerUrl = 'custom_server_url';
  static const String keyThemeMode = 'theme_mode';

  static String _runtimeUrl = '';
  static String _themeModeStr = 'system';

  /// Returns: custom URL if set, else devBaseUrl.
  static String get baseUrl =>
      _runtimeUrl.isNotEmpty ? _runtimeUrl : devBaseUrl;

  /// Returns the saved theme mode preference.
  static String get themeModeStr => _themeModeStr;

  /// Call once at app startup (before runApp).
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _runtimeUrl = prefs.getString(keyCustomServerUrl) ?? '';
    _themeModeStr = prefs.getString(keyThemeMode) ?? 'system';
  }

  /// Persist the theme mode preference and update the in-memory value.
  static Future<void> setThemeMode(String mode) async {
    _themeModeStr = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyThemeMode, mode);
  }

  /// Persist a custom server URL and update the in-memory value.
  static Future<void> setCustomUrl(String url) async {
    final trimmed = url.trim();
    _runtimeUrl = trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(keyCustomServerUrl);
    } else {
      await prefs.setString(keyCustomServerUrl, trimmed);
    }
  }

  /// Clear the custom URL (revert to default).
  static Future<void> clearCustomUrl() async {
    _runtimeUrl = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyCustomServerUrl);
  }

  static const bool mockDemoMode = bool.fromEnvironment(
    'MOCK_DEMO',
    defaultValue: false,
  );
  static bool get isDemoMode =>
      mockDemoMode || (kIsWeb && Uri.base.queryParameters.containsKey('demo'));

  static const String publicWebUrl = 'https://cookest.app';
  static const String apiPrefix = '/api';
  static const String keyFirstTime = 'cookest_first_time';
  static const String keySessionFlag = 'cookest_logged_in';
}
