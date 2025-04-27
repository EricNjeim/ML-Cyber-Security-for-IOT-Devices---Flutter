import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iotframework/core/error/exceptions.dart';
import 'package:iotframework/domain/repositories/auth_repository.dart';
import 'package:logger/logger.dart';

/// Network service that handles all API requests.
/// This simplified version delegates token management to AuthRepository.
class NetworkService {
  final Dio _dio;
  final AuthRepository _authRepository;
  final Logger? _logger;

  NetworkService({
    required Dio dio,
    required AuthRepository authRepository,
    Logger? logger,
  })  : _dio = dio,
        _authRepository = authRepository,
        _logger = logger {
    // Add logging interceptor if logger is provided
    if (_logger != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            _logger?.d(
              '🌐 REQUEST[${options.method}] => PATH: ${options.path}',
            );
            handler.next(options);
          },
          onResponse: (response, handler) {
            _logger?.d(
              '🌐 RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
            );
            handler.next(response);
          },
          onError: (err, handler) {
            _logger?.e(
              '🌐 ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
            );
            handler.next(err);
          },
        ),
      );
    }
  }

  /// Private method to get request options with valid auth headers
  Future<Options> _getOptions([Options? options]) async {
    final headers = await _authRepository.getAuthHeaders();

    final mergedOptions = options ?? Options();
    return mergedOptions.copyWith(
      headers: {...mergedOptions.headers ?? {}, ...headers},
    );
  }

  /// Private method to check authentication status before making requests
  Future<bool> _ensureAuthenticated() async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (!isLoggedIn) {
        _logger?.w('🔒 Request blocked: User not authenticated');
        debugPrint('🔒 Request blocked: Not authenticated. Login required.');
        return false;
      }

      return true;
    } catch (e) {
      _logger?.e('Error checking authentication status', error: e);
      return false;
    }
  }

  /// Makes a GET request to the specified endpoint
  Future<Response<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    // Check authentication before proceeding
    final isAuthenticated = await _ensureAuthenticated();
    if (!isAuthenticated) {
      throw UnauthorizedException();
    }

    final requestOptions = await _getOptions(options);

    try {
      return await _dio.get<T>(
        endpoint,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logError('GET', endpoint, e);
      rethrow;
    }
  }

  /// Makes a POST request to the specified endpoint
  Future<Response<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    // Special case for login/register endpoints - allow without authentication
    if (!endpoint.contains('/login') && !endpoint.contains('/register')) {
      // Check authentication before proceeding
      final isAuthenticated = await _ensureAuthenticated();
      if (!isAuthenticated) {
        throw UnauthorizedException();
      }
    }

    final requestOptions = await _getOptions(options);

    try {
      return await _dio.post<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logError('POST', endpoint, e);
      rethrow;
    }
  }

  /// Makes a PUT request to the specified endpoint
  Future<Response<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    // Check authentication before proceeding
    final isAuthenticated = await _ensureAuthenticated();
    if (!isAuthenticated) {
      throw UnauthorizedException();
    }

    final requestOptions = await _getOptions(options);

    try {
      return await _dio.put<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logError('PUT', endpoint, e);
      rethrow;
    }
  }

  /// Makes a PATCH request to the specified endpoint
  Future<Response<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    // Check authentication before proceeding
    final isAuthenticated = await _ensureAuthenticated();
    if (!isAuthenticated) {
      throw UnauthorizedException();
    }

    final requestOptions = await _getOptions(options);

    try {
      return await _dio.patch<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logError('PATCH', endpoint, e);
      rethrow;
    }
  }

  /// Makes a DELETE request to the specified endpoint
  Future<Response<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    // Check authentication before proceeding
    final isAuthenticated = await _ensureAuthenticated();
    if (!isAuthenticated) {
      throw UnauthorizedException();
    }

    final requestOptions = await _getOptions(options);

    try {
      return await _dio.delete<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
    } catch (e) {
      _logError('DELETE', endpoint, e);
      rethrow;
    }
  }

  /// Helper method to log errors
  void _logError(String method, String endpoint, dynamic error) {
    if (_logger != null && kDebugMode) {
      _logger?.e('🔴 $method request to $endpoint failed');
    }

    // Check if error is a DioException with a 401 status code
    if (error is DioException && error.response?.statusCode == 401) {
      // We don't have access to AuthRedirectService here, but the repository
      // should handle refreshing the token. If that fails too, the UI should
      // show appropriate error messages and handle redirection.
    }
  }
}
