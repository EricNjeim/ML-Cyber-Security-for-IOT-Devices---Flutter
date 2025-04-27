# iotframework

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Handling Token Expiration

Our API token refresh approach automatically handles expired tokens by using login credentials stored during successful authentication. Here's how to use it:

### Setting up token expiration handling in your services

```dart
// In your service constructor:
final NetworkService _networkService;

MyService(this._networkService) {
  // Set up a callback to handle when token refresh fails
  _networkService.setTokenExpiredCallback(() {
    // Navigate to login screen or show login dialog
    // For example:
    Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  });
}
```

### Testing token validity during app startup

```dart
Future<void> checkAuthStatus() async {
  // Check if token is still valid 
  final isValid = await _networkService.testConnection();
  
  if (!isValid) {
    // If not valid, navigate to login
    Navigator.of(context).pushReplacementNamed('/login');
  } else {
    // If valid, proceed to home screen
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
```

### How it works

1. When API requests return a 401 (Unauthorized) error, the system:
   - Attempts to refresh the token using stored credentials
   - If successful, automatically retries the original request
   - If unsuccessful, triggers the onTokenExpired callback

2. This approach prevents showing multiple login screens when several API calls fail simultaneously

3. The token refresh is protected against race conditions with a single-flight pattern
