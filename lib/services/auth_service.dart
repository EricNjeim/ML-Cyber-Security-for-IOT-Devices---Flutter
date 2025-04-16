import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token';
  final String _apiBaseUrl = 'http://192.168.101.55:3000/api';



  bool _isJwtExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return true; // malformed → treat as expired

    final payload = parts[1]
        .padRight(parts[1].length + (4 - parts[1].length % 4) % 4, '='); // padding
    final decoded = utf8.decode(base64Url.decode(payload));
    final Map<String, dynamic> map = jsonDecode(decoded);

    if (!map.containsKey('exp')) return true; // no exp → treat as expired

    final expiry = DateTime.fromMillisecondsSinceEpoch(map['exp'] * 1000);
    return DateTime.now().isAfter(expiry);
  }

  Future<void> storeToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);

    // For backward compatibility with existing code
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get token from secure storage
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    if (_isJwtExpired(token)) {
      // force a logout to clear the expired token
      await logout();
      return false;
    }

    return true;
  }


  // Login user and store token
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        // Store token securely
        await storeToken(token);

        return {
          'success': true,
          'message': 'Login successful',
          'token': token,
        };
      } else {
        logout()
;        return {
          'success': false,
          'message':
              'Login failed. Status: ${response.statusCode}, Message: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: $e',
      };
    }
  }

  // Logout user
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);

    // Clear from shared prefs too for backward compatibility
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Get auth headers for API requests
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
