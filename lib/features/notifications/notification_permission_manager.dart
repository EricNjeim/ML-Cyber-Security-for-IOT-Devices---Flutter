import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/core/services/notification_service.dart';

/// Class to manage notification permission and FCM token registration
class NotificationPermissionManager {
  final NotificationService _notificationService;

  NotificationPermissionManager(this._notificationService);

  /// Shows a dialog asking for notification permission and registers FCM token if granted
  Future<void> requestPermissionAndRegisterToken(BuildContext context) async {
    // Initialize notification service first
    await _notificationService.initialize();

    // Check if we've already requested permission
    final hasRequested = await _notificationService.hasRequestedPermission();
    if (hasRequested) {
      // Already requested before, check if permission is granted
      final isGranted = await _notificationService.checkPermissionStatus();
      if (isGranted) {
        // Permission already granted, silently register token
        await _notificationService.registerFcmToken();
      }
      return;
    }

    // Show dialog asking for permission
    final shouldRequest = await _showNotificationPermissionDialog(context);
    if (!shouldRequest) return;

    // Request system permission
    final permissionGranted =
        await _notificationService.requestNotificationPermission();
    if (!permissionGranted) {
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
      return;
    }

    // Register token with server
    final registered = await _notificationService.registerFcmToken();
    if (!registered && context.mounted) {
      _showRegistrationFailedDialog(context);
    }
  }

  /// Show dialog explaining why we need notification permission
  Future<bool> _showNotificationPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Would you like to receive notifications about security threats and attacks to your devices?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show dialog when permission is denied
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
          'Without notification permission, you won\'t receive alerts about security threats. '
          'You can enable notifications later in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show dialog when token registration fails
  void _showRegistrationFailedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Failed'),
        content: const Text(
          'Failed to register for notifications. Please check your connection and try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Provider for the notification permission manager
final notificationPermissionManagerProvider =
    Provider<NotificationPermissionManager>((ref) {
  final notificationService =
      ref.read(ServiceLocator.notificationServiceProvider);
  return NotificationPermissionManager(notificationService);
});
