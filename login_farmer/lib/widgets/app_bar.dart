import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

PreferredSizeWidget buildAppBar() {
  return AppBar(
    backgroundColor: const Color(0xFF375534),
    automaticallyImplyLeading: false,
    centerTitle: true, // Removes the back arrow
    title: Row(
      children: [
        const Icon(Icons.menu, color: Colors.white),
        const Spacer(),
        Text(
          "AgriTech Pioneers",
          style: GoogleFonts.righteous(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        const Icon(Icons.notifications, color: Colors.white),
      ],
    ),
  );
}
