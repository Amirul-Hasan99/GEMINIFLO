import 'dart:io';
import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({required SecureStorageService secureStorage, Dio? customDio}) {
    _dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: EnvConfig.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            sendTimeout: ApiConstants.sendTimeout,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

    _dio.interceptors.addAll([
      AuthInterceptor(secureStorage),
      ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<Response> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    required File file,
    required String fileFieldName,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formDataMap = Map<String, dynamic>.from(fields);
      formDataMap[fileFieldName] = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      final formData = FormData.fromMap(formDataMap);

      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}
