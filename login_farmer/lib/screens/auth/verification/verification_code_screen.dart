import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_farmer/Theme/colors.dart';
import '../../../widgets/auth/auth_button.dart';
import '../login/reset_password_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  @override
  _VerificationCodeScreenState createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Code',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/agritech_logo.jpg',
                height: 200, width: 200),
            const SizedBox(height: 30),
            const Text('Enter Verification Code',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('We have sent a verification code to your email',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            _buildCodeInputFields(),
            const SizedBox(height: 20),
            if (_hasError)
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 40),
            AuthButton(text: 'Verify', onPressed: _verifyCode),
            const SizedBox(height: 20),
            TextButton(
                onPressed: _resendCode, child: const Text('Resend Code')),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_animation.value * (index % 2 == 0 ? -1 : 1), 0),
              child: SizedBox(
                width: 60,
                height: 60,
                child: TextField(
                  controller: _controllers[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: _hasError ? Colors.red : Colors.grey),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length == 1 && index < 3) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _verifyCode() {
    String code = _controllers.map((controller) => controller.text).join();
    if (code.length < 4) {
      _setErrorState('Please enter a valid 4-digit code');
    } else {
      _clearErrorState();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => ResetPasswordScreen()));
    }
  }

  void _resendCode() async {
    String emailOrPhone =
        "user_input@example.com"; // Replace with actual user input

    try {
      if (emailOrPhone.contains("@")) {
        await FirebaseAuth.instance.currentUser?.sendEmailVerification();
        _setSuccessState("A verification email has been sent!");
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: emailOrPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await FirebaseAuth.instance.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            _setErrorState("Failed to send code: ${e.message}");
          },
          codeSent: (String verificationId, int? resendToken) {
            _setSuccessState("Verification code sent!");
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
    } catch (e) {
      _setErrorState("Error: ${e.toString()}");
    }
  }

  void _setErrorState(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void _clearErrorState() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
  }

  void _setSuccessState(String message) {
    setState(() {
      _errorMessage = message;
      _hasError = false;
    });
  }
}
