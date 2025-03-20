import 'dart:io';

import 'package:flutter/material.dart';
import 'package:login_farmer/Theme/colors.dart';
import 'package:login_farmer/pages/history.dart';
import 'package:login_farmer/pages/payment.dart';
import 'package:login_farmer/pages/view_profile.dart';
import 'package:login_farmer/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "Guest User";
  String email = "No email found";
  String userId = "No ID found";
  String phoneNumber = "No phone number found";
  String imageUrl = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final apiService = ApiService();

    // First try to get data from API
    final userProfile = await apiService.getUserProfile();

    if (userProfile['success']) {
      final userData = userProfile['data'];

      setState(() {
        name = userData['name'] ?? "Guest User";
        email = userData['email'] ?? "No email found";
        userId = userData['id'].toString() ?? "No ID found";
        phoneNumber = userData['phone_number'] ?? "No phone number found";
        // Update this if you have image handling
        imageUrl = userData['image_url'] ?? "";
      });
    } else {
      // Fallback to shared preferences if API fails
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        name = prefs.getString('user_name') ?? "Guest User";
        email = prefs.getString('user_email') ?? "No email found";
        userId = prefs.getString('user_id') ?? "No ID found";
        phoneNumber = prefs.getString('user_phone') ?? "No phone number found";
        imageUrl = prefs.getString('user_image') ?? "";
      });
    }
  }

  void _navigateTo(String route) async {
    switch (route) {
      case 'viewProfile':
        // Wait for the navigation to complete and then reload data
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViewProfile()),
        );
        _loadUserData(); // Reload data when returning from ViewProfile
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
        );
        break;
      case 'payment':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentPage()),
        );
        break;
      case 'deleteAccount':
        _confirmDeleteAccount();
        break;
      case 'logout':
        _confirmLogout();
        break;
      default:
        break;
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text('Do you want to delete your account?'),
          content: const Text(
              'If you click YES, your account and all your information will be permanently deleted, and you will not be able to retrieve your information.'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _deleteAccount();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          titleTextStyle: const TextStyle(color: AppColors.black),
          title: const Text('Information'),
          content: const Text('Do you want to Logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _logout();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear user data

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Successful'),
          content: const Text('Account deleted successfully.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final apiService = ApiService();
    await prefs.clear(); // Clear user data
    await apiService.logout();

    Navigator.of(context).pop(); // Go back to the welcome screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Account',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color(0xFF375534),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: imageUrl.isNotEmpty
                    ? FileImage(
                        File(imageUrl)) // Use FileImage for local file paths
                    : const AssetImage('assets/images/avatar.jpg')
                        as ImageProvider,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            // Center(
            //   child: Text(
            //     userId,
            //     style: const TextStyle(fontSize: 16, color: Colors.grey),
            //   ),
            // ),
            // Center(
            //   child: Text(
            //     phoneNumber, // Display phone number
            //     style: const TextStyle(fontSize: 16, color: Colors.grey),
            //   ),
            // ),
            const SizedBox(height: 60),
            _buildActionButton('View Profile', Icons.person, 'viewProfile'),
            const SizedBox(height: 10),
            _buildActionButton('History of Booking', Icons.history, 'history'),
            const SizedBox(height: 10),
            _buildActionButton('Payment', Icons.payment, 'payment'),
            const SizedBox(height: 10),
            _buildActionButton(
                'Delete Account', Icons.delete, 'deleteAccount', Colors.red),
            const SizedBox(height: 10),
            _buildActionButton('Logout', Icons.logout, 'logout', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, String route,
      [Color? textColor]) {
    return ElevatedButton(
      onPressed: () => _navigateTo(route),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.grey),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.grey),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: textColor ?? AppColors.black)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: AppColors.white),
        ],
      ),
    );
  }
}
