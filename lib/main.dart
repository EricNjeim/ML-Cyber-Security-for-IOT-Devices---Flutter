import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/core/routing/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

/// Top-level function for background Firebase Cloud Messaging (FCM) message handling
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

/// Entry point of the application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Run the app
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// The main application widget
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  String? _fcmToken;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    _initFCM();
    _initAuthRedirect();
  }

  /// Initialize local notifications
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
  }

  /// Handle notification selection
  void _onSelectNotification(NotificationResponse response) {
    print("Local Notification tapped: ${response.payload}");
    // Navigation can be implemented here based on the notification payload
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initFCM() async {
    // Request permission for notifications on iOS
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token for device
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _fcmToken = token;
    });
    print("FCM Token: $_fcmToken");

    // Store FCM token in secure storage
    if (_fcmToken != null) {
      await secureStorage.write(key: 'fcm_token', value: _fcmToken);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Notification: ${message.notification}');
        // Show a local notification to handle foreground notifications
        _showForegroundNotification(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked! Data: ${message.data}');
      // Navigation logic can be implemented here
    });

    // Check if app was opened from a notification
    _checkInitialMessage();
  }

  /// Display a local notification for foreground messages
  Future<void> _showForegroundNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformDetails,
      payload: 'Foreground Notification',
    );
  }

  /// Check if app was launched from a notification
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("App launched from notification: ${initialMessage.data}");
      // Navigation logic can be implemented here
    }
  }

  /// Initialize the auth redirect service
  void _initAuthRedirect() {
    // Access the auth redirect service to initialize it
    ref.read(ServiceLocator.authRedirectServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureIOT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.splashRoute, // Start with splash screen
    );
  }
}
