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
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePageContent(), // Now properly defined
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: buildBottomNavigationBar1(_currentIndex, (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
    );
  }

  BottomNavigationBar buildBottomNavigationBar1(
      int currentIndex, Function(int) onTap) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color(0xFF375534),
      unselectedItemColor: Colors.grey,
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

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

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

    return Scaffold(
      appBar: buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCarousel(MediaQuery.of(context).size.height, imagePaths, 0),
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
            child: buildCategoryGrid(categories, context),
          ),
        ],
      ),
    );
  }
}
