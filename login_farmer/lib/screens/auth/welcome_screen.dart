import 'package:flutter/material.dart';
import 'package:login_farmer/service/api_service.dart';
import 'package:login_farmer/widgets/auth/auth_button.dart';

import 'login/login_screen.dart';
import 'signup/signup_screen.dart';
import 'package:login_farmer/Theme/colors.dart'; // Assuming custom colors

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ApiService apiService = ApiService();
  String welcomeMessage = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchWelcomeMessage();
  }

  void fetchWelcomeMessage() async {
    var data = await apiService.getData("welcome-message"); // Laravel API route
    if (data != null) {
      setState(() {
        welcomeMessage = data["message"] ?? "No message found";
      });
    } else {
      setState(() {
        welcomeMessage = "Failed to load data";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Welcome',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Color(0xFF375534),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/agritech_logo.jpg',
                height: 400,
                width: 400,
              ),
              SizedBox(height: 20),
              Text(
                'AgriTech Pioneers',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              Text(
                welcomeMessage, // Display the welcome message fetched from Laravel
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
              SizedBox(height: 40),
              AuthButton(
                text: 'Login',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                ),
                isOutlined: false,
              ),
              SizedBox(height: 20),
              AuthButton(
                text: 'Sign Up',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                ),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
