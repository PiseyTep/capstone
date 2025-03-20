import 'package:flutter/material.dart';

import 'package:login_farmer/pages/srp.dart';
import 'package:login_farmer/pages/tractor.dart';
import 'package:login_farmer/pages/video_page.dart';
import 'package:login_farmer/pages/weather.dart'; // Import the SRP page

Widget buildCategoryGrid(
    List<Map<String, dynamic>> categories, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: GridView.builder(
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        // Debug print to check the category data
        print(categories[index]);

        // Safely access label and icon
        String label = categories[index]["label"] ?? 'No Label';
        IconData icon = categories[index]["icon"] ?? Icons.error;

        return GestureDetector(
          onTap: () {
            // Navigate to the corresponding page based on category
            switch (label) {
              case "Weather":
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => WeatherPage()));
                break;
              case "Tractor":
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TractorCategoriesPage()));
                break;
              case "Video":
                // Ensure video details are accessible
                String videoURL = categories[index]["videoURL"] ?? '';
                // Removed unused variable 'description'

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => VideoPage(videoURL: videoURL)));
                break;
              case "SRP":
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SRPPage()));
                break;
              default:
                print('Unknown category: $label');
            }
          },
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: const Color(0xFF375534)),
                const SizedBox(height: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    ),
  );
}
