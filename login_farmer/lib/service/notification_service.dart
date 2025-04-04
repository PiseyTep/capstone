// lib/services/notification/notification_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:login_farmer/service/auth_service.dart';
import 'package:login_farmer/service/notification/background_message_handler.dart';
import 'package:login_farmer/service/notification/notification_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  AuthService _authService;
  NotificationRepository _notificationRepository;

  // Channel IDs
  static const String _highImportanceChannelId = 'high_importance_channel';
  static const String _defaultChannelId = 'default_channel';

  GlobalKey<NavigatorState>? _navigatorKey;

// Private constructor
  NotificationService._internal({
    AuthService? authService,
    NotificationRepository? notificationRepository,
  })  : _authService = authService ??
            AuthService(secureStorage: const FlutterSecureStorage()),
        _notificationRepository =
            notificationRepository ?? NotificationRepository();
// Singleton factory constructor
  factory NotificationService({
    required AuthService authService,
    required NotificationRepository notificationRepository,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    _instance._authService = authService;
    _instance._notificationRepository = notificationRepository;
    _instance._navigatorKey = navigatorKey;
    return _instance;
  }
  // Initialize the notification service
  Future<void> initialize() async {
    debugPrint('📱 Initializing notification service');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission from user
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle FCM token
    await _registerFCMToken();

    // Set up message handlers
    _setupMessageHandlers();

    debugPrint('✅ Notification service initialized');
  }

  // Request permissions for notifications
  Future<void> _requestPermissions() async {
    debugPrint('🔐 Requesting notification permissions');

    // Request permission from the user
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('🔐 User granted permission: ${settings.authorizationStatus}');

    // Also request permission for local notifications on iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    debugPrint('🔔 Setting up local notifications');

    // Define the Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _highImportanceChannelId,
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize settings for iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        const DarwinInitializationSettings();

    // Initialize settings for all platforms
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification tapped: ${details.payload}');
        _handleNotificationTap(details.payload);
      },
    );

    debugPrint('🔔 Local notifications initialized');
  }

// Add this method at the class level, not inside another method
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('Received iOS local notification: $id, $title, $body, $payload');

    // Optional: You can add logic to handle the notification on iOS
    if (payload != null) {
      _handleNotificationTap(payload);
    }
  }

  // Get and register FCM token
  Future<void> _registerFCMToken() async {
    debugPrint('🔑 Getting FCM token');

    // Get the token
    String? token = await _messaging.getToken();
    debugPrint('🔑 FCM Token: ${token?.substring(0, 10)}...');

    if (token != null) {
      // Save token to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      // Register token with the backend
      bool registered = await _authService.registerDeviceToken(token);

      if (registered) {
        debugPrint('✅ Device token registered with backend');
      } else {
        debugPrint('❌ Failed to register device token with backend');
      }
    }

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token refreshed: ${newToken.substring(0, 10)}...');

      // Save new token to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);

      // Register refreshed token with backend
      await _authService.registerDeviceToken(newToken);
    });
  }

  // Set up message handlers for foreground and background messages
  void _setupMessageHandlers() {
    debugPrint('👂 Setting up Firebase message handlers');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened by tapping the notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

    debugPrint('👂 Message handlers set up');
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Received foreground message: ${message.messageId}');
    debugPrint('📬 Message data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Extract the payload data
    Map<String, dynamic> payloadData = message.data;
    String payload = json.encode(payloadData);

    // If notification contains a notification payload (not just data)
    if (notification != null) {
      debugPrint('📬 Title: ${notification.title}');
      debugPrint('📬 Body: ${notification.body}');

      // Save notification to local repository
      await _notificationRepository.saveNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        data: payloadData,
      );

      // Show local notification
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _highImportanceChannelId,
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'New notification',
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } else {
      // For data-only messages (silent notifications)
      debugPrint('📬 Received silent data message');
      await _processDataMessage(message.data);
    }
  }

  // Process data-only messages
  Future<void> _processDataMessage(Map<String, dynamic> data) async {
    debugPrint('🔄 Processing data message: $data');

    // Check for specific actions
    String? action = data['action'];

    switch (action) {
      case 'sync_data':
        debugPrint('🔄 Syncing data from server');
        // Implement your data sync logic here
        break;

      case 'update_user':
        debugPrint('🔄 Updating user data');
        // Refresh user profile from server
        break;

      case 'logout':
        debugPrint('🔄 Forcing user logout');
        await _authService.logout();
        break;

      default:
        debugPrint('⚠️ Unknown action: $action');
        break;
    }
  }

  // Handle when user taps on notification that opened the app
  Future<void> _handleNotificationOpened(RemoteMessage message) async {
    debugPrint('👆 User tapped notification: ${message.messageId}');

    // Extract notification data
    Map<String, dynamic> data = message.data;

    // Handle navigation based on notification type
    String? route = data['route'];

    if (route != null && _navigatorKey?.currentState != null) {
      debugPrint('🧭 Navigating to route: $route');

      // Convert notification data to route arguments
      Map<String, dynamic> arguments = {};

      // Add all data as arguments, but handle special keys
      data.forEach((key, value) {
        if (key != 'route' && key != 'action') {
          arguments[key] = value;
        }
      });

      // Navigate to the route
      _navigatorKey!.currentState!.pushNamed(route, arguments: arguments);
    }
  }

  // Handle notification tap from local notification
  Future<void> _handleNotificationTap(String? payload) async {
    if (payload == null) return;

    debugPrint('👆 User tapped local notification with payload: $payload');

    try {
      // Parse the payload
      Map<String, dynamic> data = json.decode(payload);

      // Extract navigation data
      String? route = data['route'];

      if (route != null && _navigatorKey?.currentState != null) {
        debugPrint('🧭 Navigating to route: $route');

        // Remove non-argument data
        data.remove('route');
        data.remove('action');

        // Navigate to the route
        _navigatorKey!.currentState!.pushNamed(route, arguments: data);
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  // Subscribe to a topic for receiving broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    debugPrint('🔔 Subscribing to topic: $topic');
    await _messaging.subscribeToTopic(topic);

    // Save subscribed topic to preferences
    final prefs = await SharedPreferences.getInstance();
    List<String> topics = prefs.getStringList('fcm_topics') ?? [];
    if (!topics.contains(topic)) {
      topics.add(topic);
      await prefs.setStringList('fcm_topics', topics);
    }

    debugPrint('✅ Subscribed to topic: $topic');
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('🔕 Unsubscribing from topic: $topic');
    await _messaging.unsubscribeFromTopic(topic);

    // Remove topic from preferences
    final prefs = await SharedPreferences.getInstance();
    List<String> topics = prefs.getStringList('fcm_topics') ?? [];
    topics.remove(topic);
    await prefs.setStringList('fcm_topics', topics);

    debugPrint('✅ Unsubscribed from topic: $topic');
  }

  // Get list of subscribed topics
  Future<List<String>> getSubscribedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('fcm_topics') ?? [];
  }

  // Get the FCM token
  Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
