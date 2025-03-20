import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:login_farmer/Theme/colors.dart';
import 'package:login_farmer/models/user_model.dart';
import 'package:login_farmer/pages/home/onboarding.dart';
import 'package:login_farmer/service/api_service.dart';
import 'package:login_farmer/service/user_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isAgreed = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Enhanced password validation
  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  // void _signUp() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => _isLoading = true);

  //   try {
  //     // Firebase user creation
  //     await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     );

  //     // Store user details in SharedPreferences
  //     final prefs = await SharedPreferences.getInstance();
  //     String uuid = Uuid().v4();
  //     await prefs.setString('user_uuid', uuid);
  //     await prefs.setString('user_name', _fullNameController.text.trim());
  //     await prefs.setString('user_phone', _phoneNumberController.text.trim());
  //     await prefs.setString('user_email', _emailController.text.trim());

  //     // Navigate to next screen
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (_) => Onboarding()),
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     _handleAuthError(e);
  //   } catch (e) {
  //     _showErrorSnackBar('An unexpected error occurred');
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  // Update your _signUp method in _SignUpScreenState class
  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAgreed) {
      _showErrorSnackBar(
          'Please agree to the Terms of Service and Privacy Policy');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Option 1: Register with Firebase first, then Laravel
      final apiService = ApiService();
      final result = await apiService.registerWithFirebase(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
      );

      if (result['success']) {
        // Save user profile to local storage
        final userService = UserService();
        final userProfile = UserProfile(
          uuid: result['firebase_uid'] ?? result['data']['id'].toString(),
          name: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          photoUrl: null,
        );

        await userService.saveUserToLocalStorage(userProfile);

        // Register device for notifications if needed
        await apiService.registerDeviceForNotifications(userProfile.uuid);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Onboarding()),
        );
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage = 'An error occurred';
    switch (e.code) {
      case 'weak-password':
        errorMessage = 'The password is too weak';
        break;
      case 'email-already-in-use':
        errorMessage = 'Email already exists';
        break;
      case 'invalid-email':
        errorMessage = 'Invalid email format';
        break;
    }
    _showErrorSnackBar(errorMessage);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Create Account', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/agritech_logo.jpg',
                  height: 200,
                  width: 200,
                ),
                _buildTextField(
                  controller: _fullNameController,
                  hintText: 'Full Name',
                  validator: (value) =>
                      value!.isEmpty ? 'Name is required' : null,
                  prefixIcon: Icons.person_outline,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneNumberController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty
                      ? 'Phone number is required'
                      : value.length < 9
                          ? 'Invalid phone number'
                          : null,
                  prefixIcon: Icons.phone_outlined,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty) return 'Email is required';
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    return !emailRegex.hasMatch(value)
                        ? 'Enter a valid email'
                        : null;
                  },
                  prefixIcon: Icons.email_outlined,
                ),
                SizedBox(height: 16),
                _buildPasswordField(
                  controller: _passwordController,
                  hintText: 'Password',
                  isVisible: _isPasswordVisible,
                  onVisibilityToggle: () => setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  }),
                  validator: (value) {
                    if (value!.isEmpty) return 'Password is required';
                    if (!_isPasswordStrong(value))
                      return 'Password must be 8+ chars, include uppercase, lowercase, number, symbol';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  isVisible: _isConfirmPasswordVisible,
                  onVisibilityToggle: () => setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  }),
                  validator: (value) {
                    if (value != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTermsCheckbox(),
                SizedBox(height: 24),
                _buildSignUpButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onVisibilityToggle,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.black, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _isAgreed,
          activeColor: AppColors.primaryColor,
          onChanged: (value) {
            setState(() {
              _isAgreed = value ?? false;
            });
          },
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.black54),
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _isAgreed && !_isLoading ? _signUp : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColors.primaryColor, // Set the background color to green
        foregroundColor: Colors.white, // Set the text color to black
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? CircularProgressIndicator(
              color: AppColors.primaryColor,
            )
          : Text(
              'Create Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
