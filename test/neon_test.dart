import 'package:flutter_test/flutter_test.dart';
import 'package:geminiflo_booking/core/database/neon_database_service.dart';

void main() {
  group('NeonDatabaseService Stub Tests', () {
    test('isConfigured returns false when no NEON_DB_PASSWORD dart-define is set', () {
      // In test environment, --dart-define is not passed, so password defaults to ''.
      final service = NeonDatabaseService();
      expect(service.isConfigured, isFalse);
    });

    test('checkConfiguration completes without throwing', () {
      final service = NeonDatabaseService();
      expect(() => service.checkConfiguration(), returnsNormally);
    });
  });
}
