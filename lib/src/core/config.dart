import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const String devBaseUrl = 'http://localhost:8080';
  static const String prodBaseUrl = 'https://api.cookest.app'; // Placeholder

  static String get baseUrl => devBaseUrl; // Switch logic here for flavors

  /// Public marketing/web app that hosts share links (e.g. meal-vote pages).
  static const String publicWebUrl = 'https://cookest.app';

  static const bool mockDemoMode = bool.fromEnvironment(
    'MOCK_DEMO',
    defaultValue: false,
  );
  static bool get isDemoMode =>
      mockDemoMode || (kIsWeb && Uri.base.queryParameters.containsKey('demo'));

  static const String apiPrefix = '/api';

  // Storage Keys
  static const String keyFirstTime = 'cookest_first_time';
  static const String keySessionFlag = 'cookest_logged_in';
}
