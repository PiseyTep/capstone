import 'package:flutter/material.dart';
import 'package:login_farmer/pages/history.dart';
import 'package:login_farmer/pages/profile.dart';
import 'package:login_farmer/widgets/app_bar.dart';
import 'package:login_farmer/widgets/carousel.dart';
import 'package:login_farmer/widgets/category_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  // Bottom navigation bar method should be inside _HomePageState, not in the widget class
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    // The Home Page Content
    HomePageContent(), // We will define this widget separately
    HistoryPage(), // Your History page
    ProfilePage(), // Your Profile page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(), // Ensure this returns a PreferredSizeWidget
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: buildBottomNavigationBar1(_currentIndex, (index) {
        setState(() {
          _currentIndex = index; // Update the current index
        });
      }),
    );
  }

  Widget buildBottomNavigationBar1(int currentIndex, Function(int) onTap) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Color(0xFF375534), // Change this to your desired color
      unselectedItemColor: Colors.grey, // Change this to your desired color

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

// HomePageContent widget that was previously directly inside _pages
class HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> imagePaths = [
      'assets/images/agriTech.jpg',
      'assets/images/agriTech.jpg',
      'assets/images/agriTech.jpg',
    ];

    List<Map<String, dynamic>> categories = [
      {"icon": Icons.agriculture, "label": "Tractor"},
      {"icon": Icons.video_camera_back, "label": "Video"},
      {"icon": Icons.wb_sunny, "label": "Weather"},
      {"icon": Icons.speaker_notes, "label": "SRP"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCarousel(MediaQuery.of(context).size.height, imagePaths,
            0), // Assuming 0 for the initial index
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Categories",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: buildCategoryGrid(categories,
              context), // Make sure this function is defined properly
        ),
      ],
    );
  }
}
