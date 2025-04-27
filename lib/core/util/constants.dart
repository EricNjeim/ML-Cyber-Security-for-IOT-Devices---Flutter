/// Constants used throughout the application
class AppConstants {
  // API
  static const String apiBaseUrl = 'http://192.168.100.76:3000/api';

  // Routes
  static const String mainRoute = '/';
  static const String loginRoute = '/login';
  static const String splashRoute = '/splash';

  // FCM
  static const String fcmChannelId = 'your_channel_id';
  static const String fcmChannelName = 'your_channel_name';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userInfoKey = 'user_info';
  static const String userEmailKey = 'user_email';
  static const String userPasswordKey = 'user_password';
  static const String authTokenTimestampKey = 'auth_token_timestamp';
}
