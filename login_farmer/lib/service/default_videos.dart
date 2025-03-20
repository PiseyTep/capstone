import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:login_farmer/service/default_videos.dart' as Firebase;
import 'package:shared_preferences/shared_preferences.dart';

// Define a list of default videos
class DefaultVideos {
  // Method to check if default videos are already added and add them if not
  static Future<void> ensureDefaultVideosExist() async {
    try {
      // Check if we've already added default videos (using shared preferences)
      final prefs = await SharedPreferences.getInstance();
      final defaultVideosAdded = prefs.getBool('default_videos_added') ?? false;

      if (defaultVideosAdded) {
        print('Default videos were already added');
        return;
      }

      // Check if videos collection is empty
      final videosCollection = FirebaseFirestore.instance.collection('videos');
      final querySnapshot = await videosCollection.limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Some videos already exist, mark as added and return
        await prefs.setBool('default_videos_added', true);
        return;
      }

      // Add default videos
      final batch = FirebaseFirestore.instance.batch();

      for (final video in _defaultVideosList) {
        final docRef = videosCollection.doc();
        batch.set(docRef, video);
      }

      await batch.commit();

      // Mark as added
      await prefs.setBool('default_videos_added', true);
      print('Default videos added successfully');
    } catch (e) {
      print('Error adding default videos: $e');
    }
  }

  // List of default videos
  static final List<Map<String, dynamic>> _defaultVideosList = [
    {
      'title': 'Reaping Rewards with Resilient Rice in Cambodia',
      'description': 'A brief introduction to our app and its features',
      'youtubeUrl': 'https://youtu.be/AC7GaBv3bYk?si=Fx6FE6Im4UKvggKN',
      //'thumbnailUrl': 'https://youtu.be/AC7GaBv3bYk?si=Fx6FE6Im4UKvggKN',
      'uploadDate': Timestamp.now(),
      'isDefault': true,
    },
    {
      'title': 'Getting Started Tutorial',
      'description':
          '#បច្ចេកទេសដាំដុះនិងថែទាំស្រូវអាយុកាលខ្លីពិស្តារលម្អិត Full Detail #cambodia farm',
      'youtubeUrl': 'https://youtu.be/wTXKcToRPM0?si=hqYsJfFD5uU_8VNL',
      //'thumbnailUrl': 'https://youtu.be/wTXKcToRPM0?si=hqYsJfFD5uU_8VNL',
      'uploadDate': Timestamp.now(),
      'isDefault': true,
    },
    {
      'title': 'Tips and Tricks',
      'description':
          'កសិកម្ម និងអភិវឌ្ឍន៍ជនបទ| ដំណាំស្រូវតាមបច្ចេកទេសទំនើប [EPS59] 030623​',
      'youtubeUrl': 'https://youtu.be/uVH2ri13rhw?si=mxBgc7FiUz8YMWpa',
      //'thumbnailUrl': 'https://youtu.be/uVH2ri13rhw?si=mxBgc7FiUz8YMWpa',

      'uploadDate': Timestamp.now(),
      'isDefault': true,
    },
  ];
}

// Add this to your main.dart or app initialization
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Ensure default videos exist
  await DefaultVideos.ensureDefaultVideosExist();

  // Continue with normal app startup
  //runApp(MyApp());
}
