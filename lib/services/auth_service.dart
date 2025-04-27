import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/domain/repositories/auth_repository.dart';

/// Service for handling authentication related operations
class AuthService {
  final AuthRepository _authRepository;

  AuthService({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Check if the user is authenticated
  Future<bool> isAuthenticated() async {
    return await _authRepository.isLoggedIn();
  }

  /// Logout the user
  Future<void> logout() async {
    await _authRepository.logout();
  }
}

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    authRepository: ref.read(ServiceLocator.authRepositoryProvider),
  );
});
