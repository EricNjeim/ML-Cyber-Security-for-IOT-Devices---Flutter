import 'package:iotframework/core/util/result.dart';

/// Interface defining authentication related operations
abstract class AuthRepository {
  /// Login with email and password
  Future<Result<Map<String, dynamic>>> login(String email, String password);

  /// Logout the current user
  Future<Result<void>> logout();

  /// Check if the user is logged in
  Future<bool> isLoggedIn();

  /// Get authentication headers for API requests
  Future<Map<String, String>> getAuthHeaders();

  /// Refresh the authentication token by re-authenticating with stored credentials
  /// This handles the case where the backend doesn't support refresh tokens
  Future<Result<bool>> refreshToken();

  /// Get a valid token, refreshing if necessary
  /// Returns a failure if unable to get a valid token
  Future<Result<String>> getValidToken();
}
