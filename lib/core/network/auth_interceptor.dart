import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Endpoints that do not require an authorization token
    final noAuthPaths = [
      '/login',
      '/google-login',
      '/register',
      '/forgot-password',
      '/reset-password',
    ];

    final isNoAuth = noAuthPaths.any((path) => options.path.contains(path));

    if (!isNoAuth) {
      final token = await _secureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }
}
