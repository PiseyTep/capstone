import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_farmer/Theme/colors.dart';
import 'package:login_farmer/screens/auth/custom_text_field.dart';

import '../../widgets/auth/auth_button.dart';
import 'verification/verification_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Image.asset(
              'assets/images/gmail.png',
              height: 350,
              width: 350,
            ),
            Text('Enter your email address to get passcode',
                style: TextStyle(
                    color: const Color.fromARGB(255, 8, 2, 2),
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            CustomTextField(
              controller: _emailController,
              hintText: 'Email',
              prefixIcon: Icons.email,
              errorText: _emailError,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? CircularProgressIndicator()
                : AuthButton(text: 'Next', onPressed: _validateAndProceed),
          ],
        ),
      ),
    );
  }

  void _validateAndProceed() async {
    String email = _emailController.text;

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => VerificationCodeScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          _emailError = 'No user found for that email.';
        });
      } else {
        setState(() {
          _emailError = 'An error occurred. Please try again.';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }
}
