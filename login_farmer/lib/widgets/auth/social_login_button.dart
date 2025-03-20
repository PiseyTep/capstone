// import 'package:flutter/material.dart';

// class SocialLoginButton extends StatelessWidget {
//   final String text;
//   final String imagePath;
//   final VoidCallback onPressed;

//   const SocialLoginButton({
//     Key? key,
//     required this.text,
//     required this.imagePath,
//     required this.onPressed,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       height: 57,
//       child: TextButton(
//         onPressed: onPressed,
//         style: TextButton.styleFrom(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(30),
//             side: BorderSide(color: Colors.grey),
//           ),
//           backgroundColor: Colors.white,
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset(
//               imagePath,
//               height: 30,
//               width: 30,
//             ),
//             SizedBox(width: 8),
//             Text(text, style: TextStyle(color: Colors.black)),
//           ],
//         ),
//       ),
//     );
//   }
// }
