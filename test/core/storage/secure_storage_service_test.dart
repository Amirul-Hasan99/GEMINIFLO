import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geminiflo_booking/core/constants/app_constants.dart';
import 'package:geminiflo_booking/core/storage/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService secureStorageService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorageService = SecureStorageService(storage: mockStorage);
  });

  group('SecureStorageService Tests', () {
    const testToken = 'secure_jwt_token_123';
    const testRefreshToken = 'refresh_jwt_token_456';

    test('saveToken writes auth token to secure storage', () async {
      when(() => mockStorage.write(
            key: AppConstants.keyAuthToken,
            value: testToken,
          )).thenAnswer((_) async {});

      await secureStorageService.saveToken(testToken);

      verify(() => mockStorage.write(
            key: AppConstants.keyAuthToken,
            value: testToken,
          )).called(1);
    });

    test('getToken returns token from secure storage', () async {
      when(() => mockStorage.read(key: AppConstants.keyAuthToken))
          .thenAnswer((_) async => testToken);

      final result = await secureStorageService.getToken();

      expect(result, testToken);
      verify(() => mockStorage.read(key: AppConstants.keyAuthToken)).called(1);
    });

    test('saveRefreshToken writes refresh token to secure storage', () async {
      when(() => mockStorage.write(
            key: AppConstants.keyRefreshToken,
            value: testRefreshToken,
          )).thenAnswer((_) async {});

      await secureStorageService.saveRefreshToken(testRefreshToken);

      verify(() => mockStorage.write(
            key: AppConstants.keyRefreshToken,
            value: testRefreshToken,
          )).called(1);
    });

    test('getRefreshToken returns refresh token from secure storage', () async {
      when(() => mockStorage.read(key: AppConstants.keyRefreshToken))
          .thenAnswer((_) async => testRefreshToken);

      final result = await secureStorageService.getRefreshToken();

      expect(result, testRefreshToken);
      verify(() => mockStorage.read(key: AppConstants.keyRefreshToken)).called(1);
    });

    test('clearAuthData deletes auth and refresh tokens', () async {
      when(() => mockStorage.delete(key: AppConstants.keyAuthToken))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: AppConstants.keyRefreshToken))
          .thenAnswer((_) async {});

      await secureStorageService.clearAuthData();

      verify(() => mockStorage.delete(key: AppConstants.keyAuthToken)).called(1);
      verify(() => mockStorage.delete(key: AppConstants.keyRefreshToken)).called(1);
    });

    test('clearAll deletes all items in secure storage', () async {
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

      await secureStorageService.clearAll();

      verify(() => mockStorage.deleteAll()).called(1);
    });
  });
}
