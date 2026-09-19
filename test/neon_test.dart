import 'package:flutter_test/flutter_test.dart';
import 'package:geminiflo_booking/core/database/neon_database_service.dart';

void main() {
  test('Initialize and verify Neon PostgreSQL database schema', () async {
    final service = NeonDatabaseService();
    try {
      await service.initializeSchema();

      final conn = await service.getConnection();
      final tables = await conn.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name;
      """);

      final tableNames = tables.map((r) => r[0].toString()).toList();
      expect(tableNames.contains('categories'), isTrue);
      expect(tableNames.contains('products'), isTrue);
      expect(tableNames.contains('users'), isTrue);
      expect(tableNames.contains('bookings'), isTrue);
      expect(tableNames.contains('payments'), isTrue);

      final products = await conn.execute('SELECT id, name, price FROM products;');
      expect(products.isNotEmpty, isTrue);
    } finally {
      await service.close();
    }
  });
}
