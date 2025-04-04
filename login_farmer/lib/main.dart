import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:login_farmer/firebase_options.dart';
import 'package:login_farmer/screens/api_test_screen.dart';
import 'package:login_farmer/screens/auth/welcome_screen.dart';
import 'package:login_farmer/service/api_service.dart';
import 'package:login_farmer/service/auth_service.dart';

final getIt = GetIt.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  print("BG Message: ${message.messageId}, Data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Prevent double initialization
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print("Firebase already initialized: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _setupNotifications();
  await setupServices();

  runApp(const MyApp());
}

Future<void> _setupNotifications() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  final initSettings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    print('FCM token refreshed: $token');
  });

  FirebaseMessaging.onMessage.listen((message) {
    final notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  });
}

Future<void> setupServices() async {
  final secureStorage = const FlutterSecureStorage();
  final authService = AuthService(secureStorage: secureStorage);
  final apiService = ApiService(authService: authService);

  // Register services
  getIt.registerSingleton<AuthService>(authService);
  getIt.registerSingleton<ApiService>(apiService);
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriTech App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF375534),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF375534),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final apiService = getIt<ApiService>();
  bool _isLoading = true;
  bool _isConnected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkApiStatus();
  }

  Future<void> _checkApiStatus() async {
    try {
      final result = await apiService.testApiConnection(); // not _apiService

      setState(() {
        _isConnected = result['success'] == true;
        _isLoading = false;
        _error = result['message'];
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isConnected) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('API connection failed', style: TextStyle(fontSize: 18)),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              ElevatedButton(
                onPressed: _checkApiStatus,
                child: const Text("Retry"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: WelcomeScreen()),
          SafeArea(
            child: ElevatedButton(
              child: const Text("API Diagnostics"),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ApiTestScreen(),
                ));
              },
            ),
          )
        ],
      ),
    );
  }
}
