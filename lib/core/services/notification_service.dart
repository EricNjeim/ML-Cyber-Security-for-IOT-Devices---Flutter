import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:iotframework/core/network/network_service.dart';
import 'package:iotframework/core/routing/app_router.dart';
import 'package:iotframework/domain/repositories/auth_repository.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle push notifications and FCM token registration
class NotificationService {
  final NetworkService _networkService;
  final Logger? _logger;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthRepository _authRepository;

  bool _isInitialized = false;

  static const String _prefNotificationRequested = 'notification_requested';

  NotificationService({
    required NetworkService networkService,
    Logger? logger,
    required AuthRepository authRepository,
  })  : _networkService = networkService,
        _logger = logger,
        _authRepository = authRepository;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configure local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Handle notification taps
    final notificationAppLaunchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      // App was launched from a notification
      final payload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null) {
        _handleNotificationTap(payload);
      }
    }

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _handleNotificationTap(response.payload!);
        }
      },
    );

    // Set up foreground notification presentation
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger?.d('📬 Notification tapped in background state');
      _handleMessageTap(message);
    });

    _isInitialized = true;
    _logger?.d('✅ Notification service initialized');
  }

  /// Handle message tap by navigating to appropriate screen
  void _handleMessageTap(RemoteMessage message) {
    final screen = message.data['screen'] ?? 'logs';
    _navigateToScreen(screen);
  }

  /// Handle notification tap from local notification
  void _handleNotificationTap(String payload) {
    _logger?.d('📬 Local notification tapped with payload: $payload');
    _navigateToScreen(payload);
  }

  /// Navigate to appropriate screen based on payload
  void _navigateToScreen(String route) {
    // Navigate based on the route
    switch (route) {
      case 'logs':
        AppRouter.navigateTo(AppRouter.mainRoute, arguments: {'tab': 1});
        break;
      default:
        // Default to logs screen
        AppRouter.navigateTo(AppRouter.mainRoute, arguments: {'tab': 1});
        break;
    }
  }

  /// Check if we've already requested notification permission
  Future<bool> hasRequestedPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefNotificationRequested) ?? false;
    } catch (e) {
      _logger?.e('Error checking notification permission request status',
          error: e);
      return false;
    }
  }

  /// Mark that we've requested notification permission
  Future<void> _markPermissionRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefNotificationRequested, true);
    } catch (e) {
      _logger?.e('Error saving notification permission request status',
          error: e);
    }
  }

  /// Request permission for notifications
  Future<bool> requestNotificationPermission() async {
    try {
      // Mark that we've requested permission
      await _markPermissionRequested();

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final isGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      _logger
          ?.d('📱 Notification permission ${isGranted ? 'granted' : 'denied'}');
      return isGranted;
    } catch (e) {
      _logger?.e('❌ Error requesting notification permission', error: e);
      return false;
    }
  }

  /// Check the current notification permission status
  Future<bool> checkPermissionStatus() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      _logger?.e('Error checking notification permission status', error: e);
      return false;
    }
  }

  /// Get the FCM token and register it with the server
  Future<bool> registerFcmToken() async {
    try {
      // First check if user is authenticated
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (!isLoggedIn) {
        _logger?.w('⚠️ Cannot register FCM token: User not authenticated');
        debugPrint('⚠️ Cannot register FCM token: Not logged in');
        return false;
      }

      final token = await _firebaseMessaging.getToken();

      if (token == null) {
        _logger?.w('⚠️ FCM token is null');
        return false;
      }

      _logger?.d('🔑 FCM token obtained');
      return await _sendTokenToServer(token);
    } catch (e) {
      _logger?.e('❌ Error registering FCM token', error: e);
      return false;
    }
  }

  /// Send the FCM token to the server
  Future<bool> _sendTokenToServer(String token) async {
    try {
      final deviceInfo = {
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'device_name': Platform.isAndroid ? 'Android Device' : 'iOS Device',
      };

      debugPrint(
          '📤 Sending FCM token to server: ${token.substring(0, 20)}...');
      debugPrint('📤 Endpoint: /register_token');
      debugPrint('📤 Device info: $deviceInfo');

      final response = await _networkService.post(
        '/register_token',
        data: deviceInfo,
      );

      final success = response.statusCode == 200;
      if (success) {
        _logger?.d('✅ FCM token registered with server');
        debugPrint('✅ FCM token registered successfully with server');
      } else {
        _logger?.w('⚠️ Failed to register FCM token: ${response.statusCode}');
        debugPrint('⚠️ Failed to register FCM token: ${response.statusCode}');
        debugPrint('⚠️ Response: ${response.data}');
      }

      return success;
    } catch (e) {
      _logger?.e('❌ Error sending FCM token to server', error: e);
      debugPrint('❌ Error sending FCM token to server: $e');
      return false;
    }
  }

  /// Handle a message when the app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger
        ?.d('📬 Received foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Show a local notification for a received FCM message
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'iot_security_channel',
      'IoT Security Alerts',
      channelDescription: 'Security alerts for your IoT devices',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['screen'] ?? 'logs',
    );
  }
}
