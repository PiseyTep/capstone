///Applications/XAMPP/xamppfiles/htdocs/LoginFarmer/login_farmer/lib/screens/api_test_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  // Connection status variables
  bool _isLoading = false;
  String _statusMessage = 'No test run yet';
  Map<String, dynamic> _testResults = {};

  // Text controller for custom URL input
  final TextEditingController _baseUrlController =
      TextEditingController(text: 'http://127.0.0.1:8000/test');

  // Text controller for custom route input
  final TextEditingController _routeController =
      TextEditingController(text: 'test');

  @override
  void dispose() {
    _baseUrlController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  // Test connection to the API
  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing connection...';
      _testResults = {};
    });

    final baseUrl = _baseUrlController.text.trim();
    final route = _routeController.text.trim();
    final fullUrl = '$baseUrl/$route';

    try {
      // Log attempt
      print('🔍 Attempting connection to: $fullUrl');

      // Make the request with a timeout
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ).timeout(const Duration(seconds: 10));

      // Log response
      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      // Process the response
      bool isJsonResponse = _isJsonResponse(response.body);
      bool isHtmlResponse = response.body.contains('<!DOCTYPE html>') ||
          response.body.contains('<html');

      // Update UI state
      setState(() {
        _isLoading = false;
        _testResults = {
          'url': fullUrl,
          'statusCode': response.statusCode,
          'isJsonResponse': isJsonResponse,
          'isHtmlResponse': isHtmlResponse,
          'body': response.body,
          'success': response.statusCode >= 200 &&
              response.statusCode < 300 &&
              isJsonResponse,
        };

        if (_testResults['success']) {
          _statusMessage = 'Connection successful!';
        } else if (response.statusCode == 404) {
          _statusMessage =
              'API route not found (404). Check your Laravel routes.';
        } else if (isHtmlResponse) {
          _statusMessage =
              'Received HTML instead of JSON. Check your Laravel API routes and middleware.';
        } else {
          _statusMessage =
              'Connection failed with status code: ${response.statusCode}';
        }
      });
    } catch (e) {
      // Handle errors
      print('❌ Connection Error: $e');

      setState(() {
        _isLoading = false;
        _testResults = {
          'url': fullUrl,
          'error': e.toString(),
          'success': false,
        };

        if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection refused')) {
          _statusMessage = 'Could not connect to server. Is Laravel running?';
        } else if (e.toString().contains('TimeoutException')) {
          _statusMessage =
              'Connection timed out. Server might be slow or unreachable.';
        } else {
          _statusMessage = 'Error: ${e.toString()}';
        }
      });
    }
  }

  // Test Laravel sanctum auth endpoints
  Future<void> _testAuthEndpoints() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing Laravel auth endpoints...';
      _testResults = {};
    });

    final baseUrl = _baseUrlController.text.trim();
    final authRoutes = ['/login', '/register', '/user'];
    final results = <String, dynamic>{};

    for (var route in authRoutes) {
      final fullUrl = '$baseUrl$route';
      try {
        print('🔍 Testing auth endpoint: $fullUrl');

        // Using different methods based on the endpoint
        http.Response response;
        if (route == '/login' || route == '/register') {
          // POST request with sample data
          response = await http
              .post(
                Uri.parse(fullUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'X-Requested-With': 'XMLHttpRequest',
                },
                body: jsonEncode({
                  'email': 'test@example.com',
                  'password': 'password',
                  if (route == '/register') 'name': 'Test User',
                  if (route == '/register') 'password_confirmation': 'password'
                }),
              )
              .timeout(const Duration(seconds: 10));
        } else {
          // GET request
          response = await http.get(
            Uri.parse(fullUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Requested-With': 'XMLHttpRequest',
            },
          ).timeout(const Duration(seconds: 10));
        }

        print('📡 Response for $route - Status Code: ${response.statusCode}');
        print('📄 Response Body: ${response.body}');

        bool isJsonResponse = _isJsonResponse(response.body);
        bool isHtmlResponse = response.body.contains('<!DOCTYPE html>') ||
            response.body.contains('<html');

        results[route] = {
          'url': fullUrl,
          'statusCode': response.statusCode,
          'isJsonResponse': isJsonResponse,
          'isHtmlResponse': isHtmlResponse,
          'body': response.body.length > 500
              ? '${response.body.substring(0, 500)}...'
              : response.body,
          // For auth endpoints, 401/422 can be valid responses
          'success': (response.statusCode >= 200 &&
                  response.statusCode < 300) ||
              (route != '/user' &&
                  (response.statusCode == 401 || response.statusCode == 422)),
        };
      } catch (e) {
        print('❌ Error testing $route: $e');
        results[route] = {
          'url': fullUrl,
          'error': e.toString(),
          'success': false,
        };
      }
    }

    setState(() {
      _isLoading = false;
      _testResults = results;

      bool anySuccess =
          results.values.any((result) => result['success'] == true);
      if (anySuccess) {
        _statusMessage =
            'Auth endpoints test complete. Some endpoints are accessible.';
      } else {
        _statusMessage =
            'All auth endpoints failed. Check Laravel Sanctum setup.';
      }
    });
  }

  // Tests if a response is valid JSON
  bool _isJsonResponse(String body) {
    try {
      jsonDecode(body);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper function to show more details about the test results
  void _showTestDetails() {
    if (_testResults.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Test Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_testResults.containsKey('url'))
                Text('URL: ${_testResults['url']}'),
              if (_testResults.containsKey('statusCode'))
                Text('Status code: ${_testResults['statusCode']}'),
              if (_testResults.containsKey('isJsonResponse'))
                Text('JSON response: ${_testResults['isJsonResponse']}'),
              if (_testResults.containsKey('isHtmlResponse'))
                Text('HTML response: ${_testResults['isHtmlResponse']}'),
              if (_testResults.containsKey('error'))
                Text('Error: ${_testResults['error']}'),
              const SizedBox(height: 16),
              const Text('Response body:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: SelectableText(_testResults.containsKey('body')
                    ? _testResults['body'].toString()
                    : 'No response body'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Provides guidance on fixing common Laravel API issues
  void _showTroubleshootingTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Troubleshooting Tips'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('1. Check if Laravel is running',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'Make sure your Laravel server is running with `php artisan serve`'),
              SizedBox(height: 12),
              Text('2. Check your API routes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'Verify routes in routes/api.php with `php artisan route:list`'),
              SizedBox(height: 12),
              Text('3. Check CORS settings',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Ensure CORS middleware is configured correctly'),
              SizedBox(height: 12),
              Text('4. Check URL and port',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('For Android emulator, use 10.0.2.2 instead of localhost'),
              Text('For iOS simulator, use localhost'),
              Text('For physical devices, use your computer\'s IP address'),
              SizedBox(height: 12),
              Text('5. API prefixes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'Make sure you\'re using the correct API prefix (usually /api)'),
              SizedBox(height: 12),
              Text('6. Laravel Sanctum',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'If using Sanctum for authentication, ensure it\'s set up correctly'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTroubleshootingTips,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // URL Configuration section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Configuration',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        border: OutlineInputBorder(),
                        hintText: 'http://127.0.0.1:8000/api/api',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _routeController,
                      decoration: const InputDecoration(
                        labelText: 'Route (e.g., test, users, products)',
                        border: OutlineInputBorder(),
                        hintText: 'test',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testApiConnection,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Test Custom Endpoint'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testAuthEndpoints,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Test Auth Endpoints'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Status and results section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Test Results:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (_testResults.isNotEmpty)
                            TextButton(
                              onPressed: _showTestDetails,
                              child: const Text('Show Details'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Testing connection...'),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _testResults.isNotEmpty &&
                                              _testResults
                                                  .containsKey('success') &&
                                              _testResults['success'] == true
                                          ? Icons.check_circle
                                          : Icons.error,
                                      color: _testResults.isNotEmpty &&
                                              _testResults
                                                  .containsKey('success') &&
                                              _testResults['success'] == true
                                          ? Colors.green
                                          : Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _statusMessage,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_testResults.isNotEmpty)
                                  if (_testResults.containsKey('url') &&
                                      _testResults.containsKey('statusCode'))
                                    Text(
                                      'API Test Result: ${_testResults['success'] ? 'SUCCESS' : 'FAILED'}\n'
                                      'URL: ${_testResults['url']}\n'
                                      'Status: ${_testResults['statusCode']}',
                                      style: const TextStyle(fontSize: 14),
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var route in _testResults.keys)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12.0),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  _testResults[route] != null &&
                                                          _testResults[route]
                                                                  ['success'] ==
                                                              true
                                                      ? Icons.check_circle
                                                      : Icons.error,
                                                  color: _testResults[route] !=
                                                              null &&
                                                          _testResults[route]
                                                                  ['success'] ==
                                                              true
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 18,
                                                ),
                                                // ...
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Endpoint: $route\n'
                                                    'Status: ${_testResults[route]['statusCode'] ?? 'N/A'}',
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
