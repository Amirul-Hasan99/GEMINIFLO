import 'package:flutter_test/flutter_test.dart';
import 'package:geminiflo_booking/features/auth/data/datasources/auth_mock_datasource.dart';

void main() {
  late AuthMockDataSource dataSource;

  setUp(() {
    dataSource = AuthMockDataSource();
  });

  group('AuthMockDataSource (User & Admin)', () {
    test('login with user credentials returns User role', () async {
      final response = await dataSource.login(
        email: 'user@geminiflo.com',
        password: 'password123',
      );

      expect(response['user'].role, 'user');
      expect(response['user'].email, 'user@geminiflo.com');
      expect(response['token'], isNotEmpty);
    });

    test('login with admin credentials returns Admin role', () async {
      final response = await dataSource.login(
        email: 'admin@geminiflo.com',
        password: 'password123',
      );

      expect(response['user'].role, 'admin');
      expect(response['user'].email, 'admin@geminiflo.com');
      expect(response['token'], isNotEmpty);
    });

    test('register successfully creates user', () async {
      final response = await dataSource.register(
        name: 'New User',
        email: 'new@gmail.com',
        phone: '08123456789',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(response['user'].email, 'new@gmail.com');
      expect(response['user'].name, 'New User');
      expect(response['user'].role, 'user');
      expect(response['token'], isNotEmpty);
    });
  });
}
