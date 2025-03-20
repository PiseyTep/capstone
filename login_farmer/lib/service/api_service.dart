import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ApiService {
  // Base URL for your Laravel API
  final String baseUrl = "http://127.0.0.1:8000/api";

  // For secure storage of tokens
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  Future<Map<String, dynamic>> registerWithFirebase(
      String name, String email, String password,
      {String? phoneNumber}) async {
    try {
      // First register with Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return {'success': false, 'message': 'Firebase registration failed'};
      }

      // Get Firebase ID token
      final String? idToken = await firebaseUser.getIdToken();

      // Then register with Laravel, sending the Firebase token for verification
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $idToken', // Optional: if your Laravel API verifies Firebase tokens
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'firebase_uid': firebaseUser.uid,
          'phone_number': phoneNumber,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registration successful',
          'data': responseData,
          'firebase_uid': firebaseUser.uid
        };
      } else {
        // If Laravel registration fails, delete the Firebase user
        await firebaseUser.delete();

        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed'
        };
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password is too weak';
          break;
        case 'email-already-in-use':
          message = 'Email already exists';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        default:
          message = 'Firebase error: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Registration error: $e'};
    }
  }

  // Add this method for registering devices for notifications
  Future<bool> registerDeviceForNotifications(String userId) async {
    try {
      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return false;

      // Register token with your Laravel backend
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/register-device'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_token': fcmToken,
          'user_id': userId,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
        }),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Failed to register device: $e');
      return false;
    }
  }

  // Headers for authenticated requests
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Headers for public requests
  Map<String, String> _getPublicHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // User login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _getPublicHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Store token securely
        if (responseData['token'] != null) {
          await _secureStorage.write(
              key: 'auth_token', value: responseData['token']);
        }

        // Store user data
        if (responseData['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          final user = responseData['user'];
          await prefs.setString('user_id', user['id'].toString());
          await prefs.setString('user_name', user['name'] ?? '');
          await prefs.setString('user_email', user['email'] ?? '');
        }

        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password,
      {String? phoneNumber}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _getPublicHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registration successful',
          'data': responseData
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      );

      // Clear stored data regardless of response
      await _secureStorage.delete(key: 'auth_token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');

      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  // Generic GET request
  Future<Map<String, dynamic>> getData(String endpoint,
      {bool requiresAuth = false}) async {
    try {
      final headers =
          requiresAuth ? await _getAuthHeaders() : _getPublicHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Request failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> postData(
      String endpoint, Map<String, dynamic> data,
      {bool requiresAuth = false}) async {
    try {
      final headers =
          requiresAuth ? await _getAuthHeaders() : _getPublicHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Request failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return token != null;
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    return await getData('user', requiresAuth: true);
  }
}
