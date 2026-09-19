import 'dart:io';
import 'package:dio/dio.dart';
import 'api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException apiException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        apiException = ApiException.timeout();
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        apiException = ApiException.fromStatusCode(statusCode, responseData);
        break;

      case DioExceptionType.cancel:
        apiException = const ApiException(
          message: 'Permintaan dibatalkan.',
        );
        break;

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        if (err.error is SocketException) {
          apiException = ApiException.networkError();
        } else {
          apiException = ApiException.fromStatusCode(err.response?.statusCode, err.response?.data);
        }
        break;
    }

    // Pass custom transformed exception
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      ),
    );
  }
}
