import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iotframework/home_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iotframework/services/auth_service.dart';

// Add these Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 1) Import for local notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 2) Top-level or static function for background FCM messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're using other Firebase services in the background,
  // make sure to initialize Firebase here as well.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3) Initialize Firebase before runApp
  await Firebase.initializeApp();

  // 4) Set the background messaging handler early
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 5) Then run your app
  runApp(const MyApp());
}

// 6) Convert MyApp to a StatefulWidget to handle FCM setup in initState
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _fcmToken;

  // Adjust this to your server's base URL
  final String serverUrl = 'http://192.168.101.55:3000';

  // Create a FlutterLocalNotificationsPlugin instance
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initLocalNotifications(); // (A) Initialize local notifications
    _initFCM(); // (B) Initialize Firebase Messaging
  }

  /// (A) Set up local notifications
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

  // Handle when user taps the local notification (in foreground)
  void _onSelectNotification(NotificationResponse response) {
    print("Local Notification tapped: ${response.payload}");
    // If you want to navigate to a specific screen:
    // Navigator.push(context, MaterialPageRoute(builder: (_) => SomeScreen()));
  }

  /// (B) Initialize Firebase Messaging: request permissions (iOS), get token, etc.
  Future<void> _initFCM() async {
    // On iOS, you must request permission
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

    // Retrieve the FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _fcmToken = token;
    });
    print("FCM Token: $_fcmToken");

    // Optionally, send the token to your backend so it can send you notifications
    if (_fcmToken != null) {
      _sendTokenToBackend(_fcmToken!);
    }

    // Foreground messages: show a local notification or update UI
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Notification: ${message.notification}');
        // Show a local notification to mimic normal push behavior in foreground
        _showForegroundNotification(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });

    // When a user taps on the notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked! Data: ${message.data}');
      // Navigate to a specific screen if needed
      // e.g., Navigator.push(context, MaterialPageRoute(builder: (_) => SomeScreen()));
    });

    // (Optional) If the app was killed and opened via a notification:
    _checkInitialMessage();
  }

  /// Display a local notification for a foreground FCM message
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

  /// Check if the app was launched from a terminated state via notification
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("App launched from notification: ${initialMessage.data}");
      // Navigate to a particular screen if needed:
      // Navigator.push(context, MaterialPageRoute(builder: (_) => SomeScreen()));
    }
  }

  /// Example method to send the FCM token to your Flask (or other) backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/register_token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      if (response.statusCode == 200) {
        print('Token registered successfully on the server.');
      } else {
        print('Error registering token: ${response.body}');
      }
    } catch (e) {
      print('Exception occurred while sending token to server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Attack Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SignInPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// Keep your existing SignInPage and logic here
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<StatefulWidget> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final bool isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      // Navigate to HomePage if already logged in
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final result = await _authService.login(
          emailController.text, passwordController.text);

      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Login failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "IoT Attack Detection",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enter your email and password to log in",
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: "email@domain.com",
                          filled: true,
                          fillColor: Colors.green[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Password",
                          filled: true,
                          fillColor: Colors.green[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.greenAccent,
                            )
                          : ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
