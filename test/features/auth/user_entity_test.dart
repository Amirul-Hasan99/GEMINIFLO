import 'package:flutter_test/flutter_test.dart';
import 'package:geminiflo_booking/features/auth/domain/entities/user.dart';

void main() {
  group('User Entity Tests', () {
    test('User entity correctly identifies admin role', () {
      const admin = User(
        id: 'user-001',
        name: 'Admin Geminiflo',
        email: 'admin@geminiflo.com',
        role: 'admin',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isUser, isFalse);
    });

    test('User entity correctly identifies regular user role', () {
      const customer = User(
        id: 'user-002',
        name: 'Customer Geminiflo',
        email: 'user@example.com',
        role: 'user',
      );

      expect(customer.isAdmin, isFalse);
      expect(customer.isUser, isTrue);
    });
  });
}
