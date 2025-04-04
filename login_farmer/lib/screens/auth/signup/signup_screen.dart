///Applications/XAMPP/xamppfiles/htdocs/LoginFarmer/login_farmer/lib/screens/auth/signup/signup_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:login_farmer/Theme/colors.dart';
import 'package:login_farmer/main.dart';
import 'package:login_farmer/models/user_model.dart';
import 'package:login_farmer/pages/home/onboarding.dart';
import 'package:login_farmer/service/api_service.dart';
import 'package:login_farmer/service/auth_service.dart';
import 'package:login_farmer/service/user_service.dart';

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
  double _passwordStrength = 0.0;

  // Comprehensive phone number validation
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Validate phone number length and format
    if (digitsOnly.length < 9 || digitsOnly.length > 14) {
      return 'Invalid phone number length';
    }

    // Optional: Add country-specific validation (e.g., Cambodian phone numbers)
    final phoneRegex = RegExp(r'^(0|(\+855))[1-9]\d{7,8}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Invalid phone number format';
    }

    return null;
  }

  // Enhanced password strength calculation
  double _calculatePasswordStrength(String password) {
    double strength = 0;

    if (password.length >= 8) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    return strength;
  }

  // Email domain validation
  bool _isAllowedEmailDomain(String email) {
    final allowedDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      // Add your allowed domains
    ];

    final domain = email.split('@').last.toLowerCase();
    return allowedDomains.contains(domain);
  }

  // Enhanced error handling
  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage = 'An unexpected error occurred';

    final errorMap = {
      'weak-password':
          'The password is too weak. Please use a stronger password.',
      'email-already-in-use':
          'This email is already registered. Try logging in or use a different email.',
      'invalid-email':
          'The email address is not valid. Please check and try again.',
      'operation-not-allowed': 'Password sign-in is disabled for this project.',
      'user-disabled': 'This user account has been disabled.',
    };

    errorMessage = errorMap[e.code] ?? errorMessage;

    // Log the error for debugging
    debugPrint('Authentication Error: ${e.code} - $errorMessage');

    _showErrorSnackBar(errorMessage);
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAgreed) {
      _showErrorSnackBar(
          'Please agree to the Terms of Service and Privacy Policy');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Enable detailed logging
      print('Starting registration for: ${_emailController.text}');

      final authService = getIt<AuthService>();

      final result = await authService.register(
        name: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
      );

      // Add comprehensive logging
      print('Full Registration Result: $result');

      if (result['success'] == true) {
        final userData = result['data']['user'];
        final userService = UserService();
        final userProfile = UserProfile(
          uuid: userData['firebase_uid'] ?? userData['id'].toString(),
          name: userData['name'],
          email: userData['email'],
          phoneNumber: userData['phone_number'],
          photoUrl: null,
        );

        await userService.saveUserToLocalStorage(userProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => Onboarding()),
          );
        }
      } else {
        // Show detailed error message
        print('Registration Error Details: ${result['message']}');
        _showErrorSnackBar(result['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('SignUp Complete Error: $e');
      _showErrorSnackBar('Registration failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  validator: _validatePhoneNumber,
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
                    if (!emailRegex.hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    if (!_isAllowedEmailDomain(value)) {
                      return 'Only specific email domains are allowed';
                    }
                    return null;
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
                  onChanged: (value) {
                    setState(() {
                      _passwordStrength = _calculatePasswordStrength(value);
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) return 'Password is required';
                    if (_passwordStrength < 0.6) {
                      return 'Password is too weak';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                _buildPasswordStrengthIndicator(),
                SizedBox(height: 16),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  isVisible: _isConfirmPasswordVisible,
                  onVisibilityToggle: () => setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  }),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
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

  Widget _buildPasswordStrengthIndicator() {
    Color strengthColor;

    if (_passwordStrength < 0.4) {
      strengthColor = Colors.red;
    } else if (_passwordStrength < 0.7) {
      strengthColor = Colors.orange;
    } else {
      strengthColor = Colors.green;
    }

    return LinearProgressIndicator(
      value: _passwordStrength,
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
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
    Function(String)? onChanged, // Add this parameter
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      onChanged: onChanged,
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
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // Ensure disabled button has a visible but muted color
        disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.6),
        disabledForegroundColor: Colors.white70,
      ),
      child: _isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors
                    .white, // Use white for contrast against the button background
                strokeWidth: 2.0,
              ),
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
