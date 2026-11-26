import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

enum Environment { development, production }

class EnvConfig {
  static Environment currentEnvironment = kReleaseMode
      ? Environment.production
      : Environment.development;
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static void setEnvironment(Environment env) {
    currentEnvironment = env;
  }

  static bool get isDev => currentEnvironment == Environment.development;
  static bool get isProd => currentEnvironment == Environment.production;

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    switch (currentEnvironment) {
      case Environment.production:
        return ApiConstants.prodBaseUrl;
      case Environment.development:
        // Override API_BASE_URL for a physical Android device or hosted backend.
        return defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8000/api'
            : 'http://127.0.0.1:8000/api';
    }
  }
}
