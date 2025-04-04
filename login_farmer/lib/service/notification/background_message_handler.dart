// lib/services/notification/background_message_handler.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This will handle background messages when the app is not active
  debugPrint('🚨 Handling background message: ${message.messageId}');
  debugPrint('📦 Background message data: ${message.data}');

  // You can add additional logic here for background message processing
  // For example, saving the message to local storage or performing a silent sync

  // Example of basic data extraction
  final String? title = message.notification?.title;
  final String? body = message.notification?.body;

  debugPrint('�title: $title');
  debugPrint('�body: $body');
}
