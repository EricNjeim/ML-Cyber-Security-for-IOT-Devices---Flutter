import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/core/services/notification_service.dart';
import 'package:iotframework/domain/usecases/auth/login.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:flutter/foundation.dart';
import 'package:iotframework/data/repositories/auth_repository_impl.dart';
import 'package:iotframework/core/util/constants.dart';

/// Authentication state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.errorMessage,
    this.userData,
  });

  /// Initial state
  factory AuthState.initial() => AuthState(
        isAuthenticated: false,
        isLoading: false,
      );

  /// Copy with method for creating new instances with modified properties
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? userData,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userData: userData ?? this.userData,
    );
  }
}

/// Auth notifier to manage authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final Login _loginUseCase;
  final Ref _ref;

  AuthNotifier({
    required Login loginUseCase,
    required Ref ref,
  })  : _loginUseCase = loginUseCase,
        _ref = ref,
        super(AuthState.initial()) {
    _checkAuthStatus();
  }

  /// Check if the user is already authenticated
  Future<void> _checkAuthStatus() async {
    debugPrint('📌 Checking authentication status...');
    final authRepository = _ref.read(ServiceLocator.authRepositoryProvider);

    // First check if we have a token
    final isLoggedIn = await authRepository.isLoggedIn();
    debugPrint('📌 Is user logged in? $isLoggedIn');

    // If we have a token and credentials, check if token is still valid
    if (isLoggedIn) {
      // Check token status for debugging
      if (authRepository is AuthRepositoryImpl) {
        final tokenStatus = await authRepository.checkTokenStatus();
        debugPrint('📌 Token status: $tokenStatus');

        // See if token might be expired based on timestamp
        try {
          final tokenTimestamp = await authRepository.secureStorage
              .read(key: AppConstants.authTokenTimestampKey);

          if (tokenTimestamp != null) {
            final timestamp = int.parse(tokenTimestamp);
            final now = DateTime.now().millisecondsSinceEpoch;
            final tokenAge = now - timestamp;

            // If token is older than 29 minutes (almost 30 min expiration)
            // Refresh it immediately during startup
            if (tokenAge > 29 * 60 * 1000) {
              debugPrint(
                  '📌 Token is likely expired (age: ${tokenAge / 1000 / 60} min), refreshing...');

              // Attempt token refresh (re-login with stored credentials)
              final refreshResult = await authRepository.refreshToken();

              refreshResult.fold(
                (success) => debugPrint('📌 Token refreshed during startup'),
                (failure) =>
                    debugPrint('📌 Token refresh failed: ${failure.message}'),
              );

              // Update status after refresh attempt
              final newIsLoggedIn = await authRepository.isLoggedIn();
              state = state.copyWith(isAuthenticated: newIsLoggedIn);
              return;
            }
          }
        } catch (e) {
          debugPrint('📌 Error checking token age: $e');
        }
      }
    }

    // Set state based on login status
    state = state.copyWith(isAuthenticated: isLoggedIn);
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _loginUseCase(email, password);

    result.fold(
      (userData) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          userData: userData,
        );

        // Register FCM token after successful login
        _registerFcmToken();
      },
      (failure) {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  /// Register FCM token with server after login
  Future<void> _registerFcmToken() async {
    try {
      final notificationService =
          _ref.read(ServiceLocator.notificationServiceProvider);

      // Initialize notification service
      await notificationService.initialize();

      // Check current permission status
      final hasPermission = await notificationService.checkPermissionStatus();

      if (hasPermission) {
        // Permission already granted, register token
        final success = await notificationService.registerFcmToken();
        debugPrint(
            '📱 FCM token registration after login: ${success ? 'success' : 'failed'}');
      } else {
        debugPrint('📱 Notification permission not granted yet');
      }
    } catch (e) {
      debugPrint('❌ Error registering FCM token after login: $e');
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    final authRepository = _ref.read(ServiceLocator.authRepositoryProvider);
    final result = await authRepository.logout();

    result.fold(
      (_) {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          userData: null,
        );
      },
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
    );
  }
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.read(ServiceLocator.loginUseCaseProvider),
    ref: ref,
  );
});
