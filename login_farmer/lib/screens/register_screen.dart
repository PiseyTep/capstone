// // register_screen.dart
// import 'package:flutter/material.dart';
// import 'package:login_farmer/service/api_service.dart';

// class RegisterScreen extends StatefulWidget {
//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   bool _isLoading = false;
//   String? _errorMessage;
//   Map<String, String> _fieldErrors = {};

//   final ApiService _apiService = ApiService();

//   @override
//   void dispose() {
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   Future<void> _register() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//       _fieldErrors = {};
//     });

//     try {
//       final result = await _apiService.register(
//         _firstNameController.text.trim(),
//         _lastNameController.text.trim(),
//         _emailController.text.trim(),
//         _passwordController.text,
//         _phoneController.text.trim(),
//       );

//       if (result['success']) {
//         // Navigate to home screen
//         Navigator.of(context).pushReplacementNamed('/home');
//       } else {
//         setState(() {
//           _errorMessage = result['message'] ?? 'Registration failed';

//           // Handle field-specific errors
//           if (result['errors'] != null && result['errors'] is Map) {
//             final errors = result['errors'] as Map;
//             errors.forEach((key, value) {
//               _fieldErrors[key.toString()] = value.toString();
//             });
//           }
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Network error: $e';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Register'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Title
//               Text(
//                 'Create a Farmer Account',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 30),

//               // First Name
//               TextFormField(
//                 controller: _firstNameController,
//                 decoration: InputDecoration(
//                   labelText: 'First Name',
//                   border: OutlineInputBorder(),
//                   errorText: _fieldErrors['first_name'],
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your first name';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),

//               // Last Name
//               TextFormField(
//                 controller: _lastNameController,
//                 decoration: InputDecoration(
//                   labelText: 'Last Name',
//                   border: OutlineInputBorder(),
//                   errorText: _fieldErrors['last_name'],
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your last name';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),

//               // Email
//               TextFormField(
//                 controller: _emailController,
//                 decoration: InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                   errorText: _fieldErrors['email'],
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your email';
//                   }
//                   // Email regex validation
//                   if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                       .hasMatch(value)) {
//                     return 'Please enter a valid email';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),

//               // Phone
//               TextFormField(
//                 controller: _phoneController,
//                 decoration: InputDecoration(
//                   labelText: 'Phone Number',
//                   border: OutlineInputBorder(),
//                   errorText: _fieldErrors['phone_number'],
//                 ),
//                 keyboardType: TextInputType.phone,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your phone number';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),

//               // Password
//               TextFormField(
//                 controller: _passwordController,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   border: OutlineInputBorder(),
//                   errorText: _fieldErrors['password'],
//                 ),
//                 obscureText: true,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a password';
//                   }
//                   if (value.length < 6) {
//                     return 'Password must be at least 6 characters';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),

//               // Confirm Password
//               TextFormField(
//                 controller: _confirmPasswordController,
//                 decoration: InputDecoration(
//                   labelText: 'Confirm Password',
//                   border: OutlineInputBorder(),
//                 ),
//                 obscureText: true,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please confirm your password';
//                   }
//                   if (value != _passwordController.text) {
//                     return 'Passwords do not match';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 24),

//               // Error message
//               if (_errorMessage != null)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 16.0),
//                   child: Text(
//                     _errorMessage!,
//                     style: TextStyle(color: Colors.red),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),

//               // Register button
//               SizedBox(
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _register,
//                   child: _isLoading
//                       ? CircularProgressIndicator(color: Colors.white)
//                       : Text('REGISTER'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),

//               // Login link
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Already have an account?'),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     child: Text('Login'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
