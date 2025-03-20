import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final IconData? prefixIcon; // For prefix icons
  final ValueChanged<String>? onChanged; // Callback for when the text changes
  final bool isPassword; // For password fields
  final bool isPasswordVisible; // To toggle password visibility
  final VoidCallback? onVisibilityToggle; // Callback for visibility toggle
  final TextInputType? keyboardType; // To specify keyboard type
  final List<TextInputFormatter>?
      inputFormatters; // To specify input formatters

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.errorText,
    this.onChanged,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onVisibilityToggle,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
      ),
      onChanged: onChanged, // Pass the onChanged callback
      obscureText:
          isPassword && !isPasswordVisible, // Handle password visibility
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }
}
