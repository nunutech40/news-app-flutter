import 'dart:async';

import 'package:dio/dio.dart';
import 'package:news_app/core/constants/api_constants.dart';
import 'package:news_app/core/network/token_provider.dart';

class AuthInterceptor extends Interceptor {
  final TokenProvider tokenProvider;
  final Dio dio;

  // Lock mechanism: prevents multiple simultaneous refresh requests
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    required this.tokenProvider,
    required this.dio,
  });

  static const _publicPaths = [
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.health,
  ];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = _publicPaths.any(
      (path) => options.path.contains(path),
    );

    if (!isPublic) {
      // If a refresh is in progress, wait for it to complete first
      if (_isRefreshing) {
        final newToken = await _refreshCompleter?.future;
        if (newToken != null) {
          options.headers['Authorization'] = 'Bearer $newToken';
        }
      } else {
        final token = await tokenProvider.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip refresh for public paths
    final isPublic = _publicPaths.any(
      (path) => err.requestOptions.path.contains(path),
    );
    if (isPublic) return handler.next(err);

    // If already refreshing, wait for the result instead of firing another refresh
    if (_isRefreshing) {
      try {
        final newToken = await _refreshCompleter?.future;
        if (newToken != null) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(options);
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        // Refresh failed, propagate original error
      }
      return handler.next(err);
    }

    // First request to hit 401: acquire the lock and refresh
    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await tokenProvider.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter?.complete(null);
        _resetLock();
        return handler.next(err);
      }

      // Use a separate Dio instance to avoid interceptor recursion
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccessToken = response.data['data']['access_token'] as String;
        final newRefreshToken = response.data['data']['refresh_token'] as String;

        await tokenProvider.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Unblock all waiting requests with the new token
        _refreshCompleter?.complete(newAccessToken);
        _resetLock();

        // Retry the original request
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await dio.fetch(options);
        return handler.resolve(retryResponse);
      }

      _refreshCompleter?.complete(null);
      _resetLock();
    } catch (_) {
      await tokenProvider.clearTokens();
      _refreshCompleter?.complete(null);
      _resetLock();
    }

    handler.next(err);
  }

  void _resetLock() {
    _isRefreshing = false;
    _refreshCompleter = null;
  }
}
