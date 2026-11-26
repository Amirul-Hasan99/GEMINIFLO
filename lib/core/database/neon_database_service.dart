import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Flutter client only knows the API URL. Neon credentials belong in the
/// backend environment and must never be compiled into the mobile application.
class NeonConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static bool get isConfigured => apiBaseUrl.isNotEmpty;
}

/// Client-side status helper for the server-side Neon API integration.
class NeonDatabaseService {
  bool get isConfigured => NeonConfig.isConfigured;

  /// Logs a warning if the API endpoint was not supplied at build time.
  void checkConfiguration() {
    if (!NeonConfig.isConfigured) {
      developer.log(
        'Neon API URL is not configured. Pass API_BASE_URL for a backend '
        'connected to Neon; database credentials must remain on that server.',
        name: 'NeonDB',
        level: 900,
      );
    }
  }
}

/// Riverpod Provider for NeonDatabaseService
final neonDatabaseServiceProvider = Provider<NeonDatabaseService>((ref) {
  final service = NeonDatabaseService();
  service.checkConfiguration();
  return service;
});
