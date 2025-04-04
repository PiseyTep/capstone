// lib/service/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage;

  static const _jwtTokenKey = 'jwt_token';
  static const _baseUrl = 'http://127.0.0.1:8000/api';

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Constructor accepts FlutterSecureStorage
  AuthService({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  // Login function
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Firebase user not found');

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'firebase_token': idToken,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        await saveToken(responseData['token']);
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed'
        };
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _mapFirebaseError(e)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Registration function
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Firebase user not found');

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
          'firebase_uid': user.uid,
          'firebase_token': idToken,
        }),
      );

      final responseData = jsonDecode(response.body);

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          responseData['success'] == true) {
        await saveToken(responseData['token']);
        return responseData;
      } else {
        await user.delete();
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed'
        };
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _mapFirebaseError(e)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Save token in secure storage
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await _secureStorage.write(key: _jwtTokenKey, value: token);
    } catch (e) {
      debugPrint('Error saving token: $e');
      throw Exception('Failed to save token');
    }
  }

  // Get authentication headers with token
  Future<Map<String, String>> getAuthHeaders() async {
    try {
      final jwtToken = await _secureStorage.read(key: _jwtTokenKey);

      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('Not authenticated');
      }

      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      };
    } catch (e) {
      debugPrint('Error getting auth headers: $e');
      throw Exception('Failed to get authentication headers');
    }
  }

  // Clear authentication data
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: _jwtTokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Firebase error mapping
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email';
      case 'weak-password':
        return 'Weak password';
      default:
        return 'Authentication error';
    }
  }

  // Register device token with backend
  Future<bool> registerDeviceToken(String token) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/register-device'),
        headers: headers,
        body: jsonEncode({'device_token': token}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('Error registering device token: $e');
      return false;
    }
  }

  // Logout function
  Future<void> logout() async {
    try {
      final headers = await getAuthHeaders();
      await http.post(
        Uri.parse('http://127.0.0.1:8000/logout'),
        headers: headers,
      );
    } catch (e) {
      debugPrint('Logout failed: $e');
    } finally {
      await clearAuthData(); // Clears token from storage
    }
  }
}
