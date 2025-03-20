import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:login_farmer/Theme/colors.dart';

import 'package:login_farmer/pages/home/onboarding.dart';
import 'package:login_farmer/screens/auth/forgot_password_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
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
                  height: 300,
                  width: 300,
                ),
                const SizedBox(height: 20),
                _buildEmailTextField(),
                const SizedBox(height: 16),
                _buildPasswordTextField(),
                _buildForgotPasswordButton(),
                const SizedBox(height: 16),
                _buildLoginButton(),
                const SizedBox(height: 20),
                _buildDividerWithText(),
                const SizedBox(height: 20),
                _buildSocialLoginButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailTextField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: 'Email',
        prefixIcon: const Icon(Icons.email, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordTextField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  // Forgot Password Button
  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen())),
        child: Text('Forgot Password?',
            style: TextStyle(
                color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Login',
              style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  Widget _buildDividerWithText() {
    return Row(
      children: const [
        Expanded(child: Divider(thickness: 1, color: Colors.grey)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text("OR", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        Expanded(child: Divider(thickness: 1, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        // Google Sign In Button
        ElevatedButton.icon(
          icon: Image.asset(
            'assets/images/google_icon.png',
            height: 24,
            width: 24,
          ),
          label: const Text(
            'Continue with Google',
            style: TextStyle(color: Colors.black87),
          ),
          onPressed: _signInWithGoogle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.grey, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Facebook Sign In Button
        ElevatedButton.icon(
          icon: Image.asset(
            'assets/images/facebook_icon.png',
            height: 24,
            width: 24,
          ),
          label: const Text(
            'Continue with Facebook',
            style: TextStyle(color: Colors.black),
          ),
          onPressed: _signInWithFacebook,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.grey, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await _saveUserDetails(userCredential);
        _navigateToOnboarding();
      } on FirebaseAuthException catch (e) {
        _handleAuthError(e);
      } catch (e) {
        _showErrorSnackBar('Login Failed: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Future<void> _login() async {
  //   if (_formKey.currentState!.validate()) {
  //     setState(() => _isLoading = true);

  //     try {
  //       final UserCredential userCredential =
  //           await FirebaseAuth.instance.signInWithEmailAndPassword(
  //         email: _emailController.text.trim(),
  //         password: _passwordController.text.trim(),
  //       );

  //       // Get user service
  //       final userService = UserService();

  //       // Attempt to get user data from Firestore
  //       UserProfile? userProfile = await userService.getUserDataFromFirestore();

  //       // If no data in Firestore (which is unusual but possible), create minimal profile
  //       if (userProfile == null) {
  //         userProfile = UserProfile(
  //           uuid: userCredential.user!.uid,
  //           name: userCredential.user!.displayName ?? '',
  //           email: userCredential.user!.email ?? '',
  //           phoneNumber: '',
  //           photoUrl: userCredential.user!.photoURL,
  //         );
  //       }

  //       // Save to local storage
  //       await userService.saveUserToLocalStorage(userProfile);

  //       _navigateToOnboarding();
  //     } on FirebaseAuthException catch (e) {
  //       _handleAuthError(e);
  //     } catch (e) {
  //       _showErrorSnackBar('Login Failed: ${e.toString()}');
  //     } finally {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await _saveUserDetails(userCredential);
      _navigateToOnboarding();
    } catch (e) {
      _showErrorSnackBar('Google Sign In Failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);

    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();

      if (loginResult.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(
                loginResult.accessToken!.tokenString);

        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);

        await _saveUserDetails(userCredential);
        _navigateToOnboarding();
      } else {
        throw FirebaseAuthException(
          code: 'facebook-login-cancelled',
          message: 'Facebook login was cancelled or failed',
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showErrorSnackBar('Facebook Sign In Failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserDetails(UserCredential userCredential) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uuid', userCredential.user?.uid ?? '');
    await prefs.setString('user_email', userCredential.user?.email ?? '');
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Onboarding()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage = 'Login failed';
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found for this email';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password';
        break;
      case 'invalid-email':
        errorMessage = 'Invalid email format';
        break;
    }
    _showErrorSnackBar(errorMessage);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
