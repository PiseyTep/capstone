///Applications/XAMPP/xamppfiles/htdocs/LoginFarmer/login_farmer/lib/service/direct_api_client.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DirectApiClient {
  // Configurable base URL with environment detection
  // static String get baseUrl {
  //   if (kDebugMode) {
  //     // For emulators and simulators
  //     if (Platform.isAndroid) {
  //       // Android emulator - 10.0.2.2 points to host machine's localhost
  //       return 'http://10.0.2.2:8000/api/api';
  //     } else if (Platform.isIOS) {
  //       // iOS simulator - localhost points to host machine
  //       return 'http://localhost:8000/api/api';
  //     } else {
  //       // When running on desktop (testing)
  //       return 'http://127.0.0.1:8000/api/api';
  //     }
  static String get baseUrl {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'http://127.0.0.1:8000/api';
      } else if (Platform.isIOS) {
        return 'http://127.0.0.1:8000/api';
      } else {
        return 'http://127.0.0.1:8000/api';
      }
    } else {
      // Production URLs
      if (Platform.isIOS) {
        return 'http://127.0.0.1:8000/api';
      } else if (Platform.isAndroid) {
        return 'http://127.0.0.1:8000/api';
      }
      return 'http://127.0.0.1:8000/api';
    }
  }

  // Comprehensive connection testing method with enhanced logging
  static Future<Map<String, dynamic>> testComprehensiveConnection() async {
    final testUrls = ['$baseUrl/test', '$baseUrl/status', '$baseUrl/ping'];

    final results = <String, dynamic>{};

    for (final url in testUrls) {
      try {
        // Log the attempted URL
        print('🔍 Attempting connection to: $url');

        final response = await http.get(Uri.parse(url), headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        }).timeout(const Duration(seconds: 10), onTimeout: () {
          print('⏰ Timeout for URL: $url');
          return http.Response('Timeout', 408);
        });

        // Detailed logging of response
        print('📡 Response for $url:');
        print('📥 Status Code: ${response.statusCode}');
        print('📄 Response Body: ${response.body}');

        // Check if response is HTML (indicates routing issue)
        final isHtmlResponse = response.body.contains('<!DOCTYPE html>');

        // Check if response is valid JSON
        bool isJsonResponse = false;
        try {
          jsonDecode(response.body);
          isJsonResponse = true;
        } catch (e) {
          isJsonResponse = false;
        }

        results[url] = {
          'statusCode': response.statusCode,
          'body': response.body,
          'success': !isHtmlResponse &&
              isJsonResponse &&
              response.statusCode >= 200 &&
              response.statusCode < 300,
          'isHtmlResponse': isHtmlResponse,
          'isJsonResponse': isJsonResponse
        };
      } catch (e) {
        print('❌ Connection Error - URL: $url');
        print('Error Details: $e');

        results[url] = {
          'statusCode': null,
          'body': null,
          'success': false,
          'error': e.toString()
        };
      }
    }

    // Determine overall connection status
    final overallSuccess =
        results.values.any((result) => result['success'] == true);

    return {
      'success': overallSuccess,
      'details': results,
      'message': overallSuccess
          ? 'At least one endpoint is accessible'
          : 'No endpoints could be reached. Check server configuration.',
      'debugInfo': 'Attempted URLs: $testUrls'
    };
  }

  // Enhanced login method with more robust error handling
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login for: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10),
              onTimeout: () => http.Response('Login Timeout', 408));

      print('🔑 Login Response:');
      print('📥 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      // Check for HTML response (routing/server issue)
      if (response.body.contains('<!DOCTYPE html>')) {
        return {
          'success': false,
          'message': 'Server returned HTML instead of JSON. Check API routes.',
          'statusCode': response.statusCode,
          'rawResponse': response.body
        };
      }

      try {
        final responseData = jsonDecode(response.body);
        return {
          'success': response.statusCode >= 200 && response.statusCode < 300,
          'data': responseData,
          'statusCode': response.statusCode
        };
      } catch (parseError) {
        print('❌ Parsing Error: $parseError');
        return {
          'success': false,
          'message': 'Failed to parse server response',
          'rawBody': response.body,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('❌ Login Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'statusCode': null
      };
    }
  }

  // Registration method
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    String? firebaseUid,
  }) async {
    try {
      print('📝 Attempting registration for: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
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
              if (firebaseUid != null) 'firebase_uid': firebaseUid,
            }),
          )
          .timeout(const Duration(seconds: 10),
              onTimeout: () => http.Response('Registration Timeout', 408));

      print('📋 Registration Response:');
      print('📥 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      // Check for HTML response (routing/server issue)
      if (response.body.contains('<!DOCTYPE html>')) {
        return {
          'success': false,
          'message': 'Server returned HTML instead of JSON. Check API routes.',
          'statusCode': response.statusCode,
          'rawResponse': response.body
        };
      }

      try {
        final responseData = jsonDecode(response.body);
        return {
          'success': response.statusCode >= 200 && response.statusCode < 300,
          'data': responseData,
          'statusCode': response.statusCode
        };
      } catch (parseError) {
        print('❌ Parsing Error: $parseError');
        return {
          'success': false,
          'message': 'Failed to parse server response',
          'rawBody': response.body,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('❌ Registration Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'statusCode': null
      };
    }
  }

  // Method to specifically test the API connection with detailed diagnostics
  static Future<Map<String, dynamic>> testApiConnection() async {
    try {
      print('🔍 Testing API connection to: $baseUrl/test');

      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        return http.Response('Connection Timeout', 408);
      });

      print('📡 API Test Response:');
      print('📥 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      // Check if response is HTML (indicates routing issue)
      final isHtmlResponse = response.body.contains('<!DOCTYPE html>');

      // Check if response is valid JSON
      bool isJsonResponse = false;
      dynamic jsonData;
      try {
        jsonData = jsonDecode(response.body);
        isJsonResponse = true;
      } catch (e) {
        isJsonResponse = false;
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          isJsonResponse) {
        return {
          'success': true,
          'message': 'API connection successful',
          'data': isJsonResponse ? jsonData : null,
          'statusCode': response.statusCode
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message':
              'Server returned 404 with ${isJsonResponse ? 'JSON' : 'non-JSON'} response',
          'statusCode': 404
        };
      } else if (isHtmlResponse) {
        return {
          'success': false,
          'message':
              'Server returned HTML instead of JSON. Check API routes configuration.',
          'statusCode': response.statusCode
        };
      } else {
        return {
          'success': false,
          'message':
              'API connection failed with status code: ${response.statusCode}',
          'statusCode': response.statusCode,
          'body': response.body
        };
      }
    } catch (e) {
      print('❌ API Connection Test Error: $e');

      String errorMessage = 'Network error: $e';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Could not connect to server. Is the Laravel server running?';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage =
            'SSL/TLS handshake failed. Check your API URL protocol (http/https).';
      }

      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    }
  }
}
