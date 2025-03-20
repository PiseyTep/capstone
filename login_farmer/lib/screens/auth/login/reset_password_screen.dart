import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_farmer/Theme/colors.dart';
import 'package:login_farmer/screens/auth/custom_text_field.dart';

import '../../../widgets/auth/auth_button.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? verificationCode;

  const ResetPasswordScreen({Key? key, this.verificationCode})
      : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _newPasswordError;
  String? _confirmPasswordError;
  bool _isLoading = false;

  // Add password strength indicator
  double _passwordStrength = 0.0;
  String _passwordStrengthText = "Password strength";
  Color _passwordStrengthColor = Colors.grey;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password', style: TextStyle(color: Colors.white)),
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
                height: 150,
                width: 150,
              ),
              SizedBox(height: 20),
              Text(
                'Create New Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Your new password must be different from previous passwords',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 30),
              CustomTextField(
                controller: _newPasswordController,
                hintText: 'New Password',
                isPassword: true,
                errorText: _newPasswordError,
                isPasswordVisible: _isNewPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
                onChanged: (value) {
                  _checkPasswordStrength(value);
                },
              ),
              SizedBox(height: 10),
              // Password strength indicator
              LinearProgressIndicator(
                value: _passwordStrength,
                backgroundColor: Colors.grey[300],
                valueColor:
                    AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
              ),
              SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _passwordStrengthText,
                  style: TextStyle(
                    color: _passwordStrengthColor,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                isPassword: true,
                errorText: _confirmPasswordError,
                isPasswordVisible: _isConfirmPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              SizedBox(height: 40),
              _isLoading
                  ? CircularProgressIndicator(
                      color: Color(0xFF375534),
                    )
                  : AuthButton(
                      text: 'Reset Password',
                      onPressed: _resetPassword,
                    ),
              SizedBox(height: 20),
              // Password requirements
              _buildPasswordRequirements(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildRequirementRow(
              _newPasswordController.text.length >= 8, 'At least 8 characters'),
          _buildRequirementRow(
              RegExp(r'[A-Z]').hasMatch(_newPasswordController.text),
              'At least one uppercase letter'),
          _buildRequirementRow(
              RegExp(r'[a-z]').hasMatch(_newPasswordController.text),
              'At least one lowercase letter'),
          _buildRequirementRow(
              RegExp(r'[0-9]').hasMatch(_newPasswordController.text),
              'At least one number'),
          _buildRequirementRow(
              RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                  .hasMatch(_newPasswordController.text),
              'At least one special character'),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(bool isMet, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.check_circle_outline,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _checkPasswordStrength(String password) {
    // Calculate password strength
    double strength = 0;

    if (password.isEmpty) {
      strength = 0;
    } else {
      // Length check
      if (password.length >= 8) strength += 0.2;

      // Contains uppercase
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;

      // Contains lowercase
      if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;

      // Contains number
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;

      // Contains special character
      if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;
    }

    setState(() {
      _passwordStrength = strength;

      if (strength == 0) {
        _passwordStrengthText = "Password strength";
        _passwordStrengthColor = Colors.grey;
      } else if (strength < 0.4) {
        _passwordStrengthText = "Weak password";
        _passwordStrengthColor = Colors.red;
      } else if (strength < 0.8) {
        _passwordStrengthText = "Medium password";
        _passwordStrengthColor = Colors.orange;
      } else {
        _passwordStrengthText = "Strong password";
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  bool _validatePassword(String password) {
    // Basic password validation
    bool isValid = true;

    if (password.length < 8) {
      setState(() {
        _newPasswordError = 'Password must be at least 8 characters';
      });
      isValid = false;
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() {
        _newPasswordError =
            'Password must contain at least one uppercase letter';
      });
      isValid = false;
    } else if (!RegExp(r'[a-z]').hasMatch(password)) {
      setState(() {
        _newPasswordError =
            'Password must contain at least one lowercase letter';
      });
      isValid = false;
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      setState(() {
        _newPasswordError = 'Password must contain at least one number';
      });
      isValid = false;
    } else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      setState(() {
        _newPasswordError =
            'Password must contain at least one special character';
      });
      isValid = false;
    } else {
      setState(() {
        _newPasswordError = null;
      });
    }

    return isValid;
  }

  void _resetPassword() async {
    // Clear previous errors
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
      _isLoading = true;
    });

    // Validate password strength
    bool isPasswordValid = _validatePassword(_newPasswordController.text);

    // Check if passwords match
    if (_confirmPasswordController.text != _newPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    if (isPasswordValid) {
      try {
        // Get current user
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Update the password
          await user.updatePassword(_newPasswordController.text);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to login screen after successful password reset
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        } else {
          // Handle case where user session may have expired
          setState(() {
            _newPasswordError = 'Your session has expired. Please login again.';
            _isLoading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Auth specific errors
        setState(() {
          _isLoading = false;
          switch (e.code) {
            case 'requires-recent-login':
              _newPasswordError =
                  'For security reasons, please login again before changing your password.';
              break;
            case 'weak-password':
              _newPasswordError = 'This password is too weak.';
              break;
            default:
              _newPasswordError = 'Error: ${e.message}';
              break;
          }
        });

        // For requires-recent-login, we should navigate back to login
        if (e.code == 'requires-recent-login') {
          await Future.delayed(Duration(seconds: 2));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Handle general errors
        setState(() {
          _isLoading = false;
          _newPasswordError = 'An error occurred: ${e.toString()}';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
