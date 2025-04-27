import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/util/constants.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/repositories/auth_repository.dart';
import 'package:synchronized/synchronized.dart';

/// AuthRepository that re‑logs in with cached credentials when the access
/// token expires.  It stores the credentials **only after** a successful
/// login and protects the refresh flow against concurrent calls.
class AuthRepositoryImpl implements AuthRepository {
  final FlutterSecureStorage _store;
  final http.Client _client;
  final _lock = Lock();

  AuthRepositoryImpl({
    required FlutterSecureStorage secureStorage,
    http.Client? client,
  })  : _store = secureStorage,
        _client = client ?? http.Client();

  // Getter to support existing code that accesses secureStorage directly
  FlutterSecureStorage get secureStorage => _store;

  // ──────────────────────────────────────────────────────────────────────────
  //  Login
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Future<Result<Map<String, dynamic>>> login(
      String email, String password) async {
    _d('POST /login for $email');
    try {
      // Step 1: Clear any existing token/credentials to start fresh
      await _clearStoredCredentials();
      _d('Cleared existing credentials before login attempt');

      // Step 2: Make the login request
      final res = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      _d('Login response status: ${res.statusCode}');

      // Step 3: Handle non-200 responses
      if (res.statusCode != 200) {
        _d('Login failed with status: ${res.statusCode}');
        return Result.failure(
            AuthenticationFailure(message: 'Bad credentials'));
      }

      // Step 4: Parse the response
      final Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body);
        _d('Successfully parsed login response');
      } catch (e) {
        _d('Failed to parse login response: $e');
        return Result.failure(
            ServerFailure(message: 'Invalid server response'));
      }

      // Step 5: Extract token and user data
      final token = data['access_token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;

      if (token == null) {
        _d('No token in login response');
        return Result.failure(ServerFailure(message: 'No token in response'));
      }

      if (user == null) {
        _d('No user data in login response');
        return Result.failure(
            ServerFailure(message: 'No user data in response'));
      }

      // Step 6: Store credentials and token
      _d('Storing credentials and token after successful login');
      await _persist(token, email, password);

      // Verify storage was successful
      final storedToken = await _store.read(key: AppConstants.authTokenKey);
      if (storedToken == null) {
        _d('Failed to store token');
        return Result.failure(
            ServerFailure(message: 'Failed to store authentication token'));
      }

      _d('Login successful, credentials stored');

      // Step 7: Return success with user data
      return Result.success({
        'success': true,
        'message': 'Login successful',
        'user': user,
      });
    } catch (e) {
      _d('Exception during login: $e');
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Logout
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Future<Result<void>> logout() async {
    await _store.deleteAll();
    return Result.success(null);
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Future<bool> isLoggedIn() async {
    final token = await _store.read(key: AppConstants.authTokenKey);
    if (token == null) return false;
    return !_isExpired(token);
  }

  @override
  Future<Map<String, String>> getAuthHeaders() async {
    final tokenResult = await getValidToken();
    return tokenResult.fold(
      (token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      (failure) => {'Content-Type': 'application/json'},
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Token refresh (re‑login strategy)
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Future<Result<bool>> refreshToken() async {
    final tokenResult = await getValidToken();
    return tokenResult.fold(
      (token) => Result.success(true),
      (failure) => Result.failure(failure),
    );
  }

  /// Returns a *valid* JWT, re-logging if necessary.
  Future<Result<String>> getValidToken() async {
    return _lock.synchronized(() async {
      try {
        // Check if we have a stored token
        final stored = await _store.read(key: AppConstants.authTokenKey);
        if (stored != null && !_isExpired(stored)) {
          _d('Found valid token, no refresh needed');
          return Result.success(stored);
        }

        _d('Token expired or missing, attempting to refresh with stored credentials');

        // Need to re-login with stored credentials
        final email = await _store.read(key: AppConstants.userEmailKey);
        final pwd = await _store.read(key: AppConstants.userPasswordKey);

        if (email == null || pwd == null) {
          _d('No stored credentials found for token refresh');
          return Result.failure(
              AuthenticationFailure(message: 'No cached credentials'));
        }

        _d('Refreshing token with stored credentials: $email');

        // Re-login with stored credentials to get a new token
        final loginResult = await login(email, pwd);

        // Extract the result
        bool success = false;
        String? newToken;

        // Directly read the token after login to ensure it's there
        loginResult.fold((userData) async {
          success = true;
          // Read the token directly from storage after a successful login
          newToken = await _store.read(key: AppConstants.authTokenKey);
          _d('Token refresh succeeded, got new token: ${newToken != null}');
        }, (failure) {
          _d('Token refresh failed: ${failure.message}');
          success = false;
        });

        // Now return the result based on whether we got a new token
        if (success && newToken != null) {
          return Result.success(newToken!);
        } else {
          return Result.failure(
              AuthenticationFailure(message: 'Failed to refresh token'));
        }
      } catch (e) {
        _d('Exception in getValidToken: $e');
        return Result.failure(ServerFailure(message: e.toString()));
      }
    });
  }

  bool _isExpired(String jwt) {
    try {
      return Jwt.isExpired(jwt);
    } catch (_) {
      return true;
    }
  }

  Future<void> _persist(String token, String email, String pwd) async {
    _d('Persisting credentials and token');
    await Future.wait([
      _store.write(key: AppConstants.authTokenKey, value: token),
      _store.write(key: AppConstants.userEmailKey, value: email),
      _store.write(key: AppConstants.userPasswordKey, value: pwd),
      _store.write(
          key: AppConstants.authTokenTimestampKey,
          value: DateTime.now().millisecondsSinceEpoch.toString()),
    ]);
  }

  /// Convenience helper for integration tests.
  Future<bool> testTokenRefresh() async {
    final result = await refreshToken();
    bool success = false;
    result.fold(
      (value) => success = true, // onSuccess
      (_) => success = false, // onFailure
    );
    return success;
  }

  /// Helper method for debugging token status
  Future<Map<String, dynamic>> checkTokenStatus() async {
    final token = await _store.read(key: AppConstants.authTokenKey);
    final email = await _store.read(key: AppConstants.userEmailKey);
    final password = await _store.read(key: AppConstants.userPasswordKey);

    bool isExpired = true;
    if (token != null) {
      isExpired = _isExpired(token);
    }

    return {
      'hasToken': token != null,
      'tokenLength': token?.length ?? 0,
      'hasEmail': email != null,
      'hasPassword': password != null,
      'isLoggedIn': await isLoggedIn(),
      'isExpired': isExpired,
    };
  }

  /// Debug method to print all stored auth-related values
  Future<void> debugStoredCredentials() async {
    final token = await _store.read(key: AppConstants.authTokenKey);
    final email = await _store.read(key: AppConstants.userEmailKey);
    final password = await _store.read(key: AppConstants.userPasswordKey);
    final timestamp =
        await _store.read(key: AppConstants.authTokenTimestampKey);

    _d('🔐 STORED CREDENTIALS DEBUG:');
    _d('  - Token exists: ${token != null}');
    _d('  - Token length: ${token?.length ?? 0}');
    _d('  - Token expired: ${token != null ? _isExpired(token) : "N/A"}');
    _d('  - Email exists: ${email != null}');
    _d('  - Email value: ${email ?? "NULL"}');
    _d('  - Password exists: ${password != null}');
    _d('  - Password value: ${password != null ? "******" : "NULL"}');
    _d('  - Token timestamp: ${timestamp ?? "NULL"}');
  }

  void _d(Object o) {
    if (kDebugMode) print(o);
  }

  Future<void> _clearStoredCredentials() async {
    await _store.deleteAll();
  }
}
