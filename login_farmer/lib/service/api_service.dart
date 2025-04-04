import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:login_farmer/service/auth_service.dart';

class ApiService {
  static const String _devBaseUrl = 'http://127.0.0.1:8000';
  static const String _prodBaseUrl = 'http://127.0.0.1:8000';
  final AuthService _authService;

  // Constructor now accepts an instance of AuthService
  ApiService({required AuthService authService}) : _authService = authService;

  String get baseUrl => kReleaseMode ? _prodBaseUrl : _devBaseUrl;

  // Generic method to handle GET requests
  Future<Map<String, dynamic>> getData(String endpoint,
      {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = requiresAuth
          ? await _authService.getAuthHeaders()
          : {'Content-Type': 'application/json'};

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Generic method to handle POST requests
  Future<Map<String, dynamic>> postData(
      String endpoint, Map<String, dynamic> data,
      {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = requiresAuth
          ? await _authService.getAuthHeaders()
          : {'Content-Type': 'application/json'};

      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Generic method to handle PUT requests
  Future<Map<String, dynamic>> putData(
      String endpoint, Map<String, dynamic> data,
      {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = requiresAuth
          ? await _authService.getAuthHeaders()
          : {'Content-Type': 'application/json'};

      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Generic method to handle DELETE requests
  Future<Map<String, dynamic>> deleteData(String endpoint,
      {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = requiresAuth
          ? await _authService.getAuthHeaders()
          : {'Content-Type': 'application/json'};

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Handle the API response based on status code
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseData = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'errors': responseData['errors'] ?? {},
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode
      };
    }
  }

  // Helper methods for specific API endpoints
  Future<Map<String, dynamic>> getProducts() async => getData('products');
  Future<Map<String, dynamic>> getRentals() async => getData('rentals');
  Future<Map<String, dynamic>> getProfile() async => getData('profile');
  Future<Map<String, dynamic>> getVideos() async => getData('videos');
  Future<Map<String, dynamic>> getVideoDetails(int id) async {
    return getData('videos/$id');
  }

  // Testing the API connection
  Future<Map<String, dynamic>> testApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200 && data['status'] == 'online',
        'message': data['message'] ?? 'API is reachable',
        'data': data
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'API connection failed: $e',
      };
    }
  }
}
