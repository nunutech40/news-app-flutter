import 'package:dio/dio.dart';
import 'package:news_app/core/constants/api_constants.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/network/auth_interceptor.dart';
import 'package:news_app/core/network/token_provider.dart';

/// Wraps Dio and provides clean HTTP methods.
/// All remote datasources should use this instead of raw Dio.
class ApiClient {
  final Dio _dio;

  /// Production constructor — creates Dio internally with interceptors.
  ApiClient({required TokenProvider tokenProvider})
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.addAll([
      AuthInterceptor(
        tokenProvider: tokenProvider,
        dio: _dio,
      ),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ),
    ]);
  }

  /// Test constructor — accepts a pre-configured Dio instance.
  ApiClient.withDio(this._dio);

  /// Single entry point for all HTTP requests.
  ///
  /// Usage:
  /// ```dart
  /// final data = await apiClient.request('GET', '/api/v1/auth/me');
  /// final data = await apiClient.request('POST', '/api/v1/auth/login', data: {...});
  /// ```
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Parse response — ensures we always return a Map
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {'data': response.data};
  }

  /// Convert DioException to our domain exceptions
  ServerException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection.';
        break;
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          message = data['message'] as String? ?? 'Server error';
        } else {
          message = 'Server error ($statusCode)';
        }
        break;
      default:
        message = e.message ?? 'Something went wrong';
    }

    return ServerException(message: message, statusCode: statusCode);
  }
}
