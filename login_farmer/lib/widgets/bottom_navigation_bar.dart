// import 'package:farmer_interface/pages/history.dart';
// import 'package:farmer_interface/pages/profile.dart';
// import 'package:flutter/material.dart';


// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _currentIndex = 0;

//   final List<Widget> _pages = [
//     Center(child: Text('Home Page', style: TextStyle(fontSize: 24))),
//     HistoryPage(), // Your History page
//     ProfilePage(), // Your Profile page
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('My App')),
//       body: _pages[_currentIndex], // Display the selected page
//       bottomNavigationBar: buildBottomNavigationBar1(_currentIndex, (index) {
//         setState(() {
//           _currentIndex = index; // Update the current index
//         });
//       }),
//     );
//   }
// }

// Widget buildBottomNavigationBar1(int currentIndex, Function(int) onTap) {
//   return BottomNavigationBar(
//     currentIndex: currentIndex,
//     onTap: onTap,
//     items: const [
//       BottomNavigationBarItem(
//         icon: Icon(Icons.home),
//         label: 'Home',
//       ),
//       BottomNavigationBarItem(
//         icon: Icon(Icons.history),
//         label: 'History of Booking',
//       ),
//       BottomNavigationBarItem(
//         icon: Icon(Icons.account_circle),
//         label: 'Profile',
//       ),
//     ],
//     selectedItemColor: Colors.green,
//     unselectedItemColor: Colors.grey,
//     backgroundColor: Colors.white,
//     showUnselectedLabels: true,
//     type: BottomNavigationBarType.fixed,
//   );
// }import 'package:flutter/material.dart';
// import 'history_page.dart'; // Import your History page
// import 'profile_page.dart'; // Import your Profile page

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _currentIndex = 0;

//   final List<Widget> _pages = [
//     Center(child: Text('Home Page', style: TextStyle(fontSize: 24))),
//     HistoryPage(), // Your History page
//     ProfilePage(), // Your Profile page
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('My App')),
//       body: _pages[_currentIndex], // Display the selected page
//       bottomNavigationBar: buildBottomNavigationBar(_currentIndex, (index) {
//         setState(() {
//           _currentIndex = index; // Update the current index
//         });
//       }),
//     );
//   }
// }

// Widget buildBottomNavigationBar(int currentIndex, Function(int) onTap) {
//   return BottomNavigationBar(
//     currentIndex: currentIndex,
//     onTap: onTap,
//     items: const [
//       BottomNavigationBarItem(
//         icon: Icon(Icons.home),
//         label: 'Home',
//       ),
//       BottomNavigationBarItem(
//         icon: Icon(Icons.history),
//         label: 'History of Booking',
//       ),
//       BottomNavigationBarItem(
//         icon: Icon(Icons.account_circle),
//         label: 'Profile',
//       ),
//     ],
//     selectedItemColor: Colors.green,
//     unselectedItemColor: Colors.grey,
//     backgroundColor: Colors.white,
//     showUnselectedLabels: true,
//     type: BottomNavigationBarType.fixed,
//   );
// }