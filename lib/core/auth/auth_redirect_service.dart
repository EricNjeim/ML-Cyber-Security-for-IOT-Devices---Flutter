import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iotframework/core/network/network_service.dart';
import 'package:iotframework/core/routing/app_router.dart';
import 'package:iotframework/core/util/constants.dart';

/// Service to handle authentication redirects when tokens expire
class AuthRedirectService {
  final NetworkService _networkService;
  bool _isRedirecting = false;

  // Add flag to track if app just launched
  DateTime? _serviceInitTime;
  int _redirectCount = 0;

  AuthRedirectService({
    required NetworkService networkService,
  }) : _networkService = networkService {
    _serviceInitTime = DateTime.now();
  }

  /// Handle token expiration by redirecting to login screen
  void handleTokenExpired() {
    if (_isRedirecting) {
      debugPrint('🚫 Already in process of redirecting, ignoring callback');
      return;
    }

    // Track redirect attempts for debugging
    _redirectCount++;
    debugPrint(
        '🔄 Token expired callback triggered (attempt #$_redirectCount)');

    // Don't redirect in the first 3 seconds after launch (startup time)
    // This prevents redirects during initial app loading and auth checks
    if (_serviceInitTime != null) {
      final timeSinceInit = DateTime.now().difference(_serviceInitTime!);
      if (timeSinceInit.inSeconds < 3) {
        debugPrint('🕒 Ignoring token expired callback during app startup');
        return;
      }
    }

    // Check if we're already on the login screen to prevent infinite redirects
    final currentState = AppRouter.navigatorKey.currentState;
    if (currentState == null) {
      debugPrint('⚠️ Navigator state is null, cannot redirect');
      return;
    }

    // Get current route
    final currentRoute = ModalRoute.of(currentState.context)?.settings.name;
    debugPrint('🧭 Current route: $currentRoute');

    // If we're already on the login or splash screen, don't redirect again
    if (currentRoute == AppConstants.loginRoute ||
        currentRoute == AppConstants.splashRoute) {
      debugPrint('⚠️ Already on auth screen, skipping redirect');
      return;
    }

    _isRedirecting = true;

    // Use a small delay to ensure we're not in the middle of a build
    Future.delayed(const Duration(milliseconds: 100), () {
      debugPrint('🔑 Token expired, redirecting to login screen');

      // Navigate to login screen, replacing the current route
      AppRouter.navigateToReplacement(AppConstants.loginRoute);

      _isRedirecting = false;
    });
  }
}
