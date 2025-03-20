import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Create an instance of FlutterSecureStorage
final storage = FlutterSecureStorage();

// Save token securely
Future<void> saveToken(String token) async {
  await storage.write(key: 'auth_token', value: token);
}

// Get stored token
Future<String?> getToken() async {
  return await storage.read(key: 'auth_token');
}

// Delete token
Future<void> deleteToken() async {
  await storage.delete(key: 'auth_token');
}
