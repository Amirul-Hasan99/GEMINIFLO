import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Database configuration loaded from compile-time --dart-define flags.
/// NEVER hardcode credentials here. Inject via:
/// flutter run --dart-define=NEON_DB_PASSWORD=xxx --dart-define=NEON_DB_USER=xxx
class NeonConfig {
  static const String host = String.fromEnvironment(
    'NEON_DB_HOST',
    defaultValue: 'ep-snowy-haze-at8e3hc2-pooler.c-9.us-east-1.aws.neon.tech',
  );
  static const int port = int.fromEnvironment('NEON_DB_PORT', defaultValue: 5432);
  static const String database = String.fromEnvironment(
    'NEON_DB_NAME',
    defaultValue: 'GEMINIFLO',
  );
  static const String username = String.fromEnvironment(
    'NEON_DB_USER',
    defaultValue: 'neondb_owner',
  );
  static const String password = String.fromEnvironment(
    'NEON_DB_PASSWORD',
    defaultValue: '',
  );

  static bool get isConfigured => password.isNotEmpty && host.isNotEmpty;

  static String get connectionString =>
      'postgresql://$username:$password@$host/$database?sslmode=require&channel_binding=require';
}

/// Stub database service.
///
/// NOTE: Direct client-to-PostgreSQL connections from a mobile app violate
/// 3-tier security architecture. This service is kept as a future migration
/// point for a proper backend API layer (REST/GraphQL).
///
/// For production, replace this with calls to a secure backend API endpoint
/// (e.g., FastAPI, NestJS, Supabase) that performs authenticated DB access.
class NeonDatabaseService {
  bool get isConfigured => NeonConfig.isConfigured;

  /// Logs a warning if the app is not configured with DB credentials.
  void checkConfiguration() {
    if (!NeonConfig.isConfigured) {
      developer.log(
        'NeonDB: No database password configured. '
        'Pass --dart-define=NEON_DB_PASSWORD=xxx when running. '
        'App will use mock data sources.',
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
