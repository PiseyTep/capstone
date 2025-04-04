///Applications/XAMPP/xamppfiles/htdocs/LoginFarmer/login_farmer/lib/screens/auth/welcome_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:login_farmer/screens/auth/login/login_screen.dart';
import 'package:login_farmer/screens/auth/signup/signup_screen.dart';
import 'package:login_farmer/screens/register_screen.dart';
import 'package:login_farmer/service/api_service.dart';
import 'package:login_farmer/service/auth_service.dart';
import 'package:login_farmer/widgets/auth/auth_button.dart';
import 'package:login_farmer/Theme/colors.dart';
import 'package:get_it/get_it.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final ApiService _apiService;
  String _welcomeMessage = "Loading...";
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Get instance from service locator instead of creating new
    _apiService = GetIt.I<ApiService>();
    _fetchWelcomeMessage();
  }

  Future<void> _fetchWelcomeMessage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Option 1: Use an existing public endpoint
      final data = await _apiService
          .getData("products/public", requiresAuth: false)
          .timeout(const Duration(seconds: 10));

      setState(() {
        // Just display a static welcome message
        _welcomeMessage =
            "Welcome to AgriTech Pioneers - Connecting farmers with technology";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Display a static welcome message without showing an error
        _welcomeMessage = "Welcome to AgriTech Pioneers";
        // Don't set error message for a better user experience
        // _errorMessage = _getErrorMessage(e);
      });
      debugPrint("Error fetching data: $e");
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return "Connection timeout. Please try again.";
    } else if (error.toString().contains("SocketException")) {
      return "No internet connection";
    }
    return "Failed to load welcome message";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Welcome',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 20),
              _buildTitle(),
              const SizedBox(height: 40),
              _buildWelcomeMessage(),
              const SizedBox(height: 40),
              _buildAuthButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/agritech_logo.jpg',
      height: 200, // Reduced size for better mobile view
      width: 200,
      fit: BoxFit.contain,
    );
  }

  Widget _buildTitle() {
    return const Text(
      'AgriTech Pioneers',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    if (_isLoading) {
      return const CircularProgressIndicator(
        color: AppColors.primaryColor,
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _welcomeMessage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Text(
      _welcomeMessage,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Column(
      children: [
        AuthButton(
          text: 'Login',
          onPressed: () => _navigateTo(context, LoginScreen()),
          isOutlined: false,
        ),
        const SizedBox(height: 20),
        AuthButton(
          text: 'Sign Up',
          onPressed: () => _navigateTo(context, SignUpScreen()),
          isOutlined: true,
        ),
        const SizedBox(height: 20),
        // AuthButton(
        //   text: 'RegisterScreen', // Remove the duplication
        //   onPressed: () => _navigateTo(context, RegisterScreen()),
        //   isOutlined: true,
        // ),
      ],
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}
