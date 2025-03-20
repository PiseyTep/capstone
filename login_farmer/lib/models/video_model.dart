// In video_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String title;
  final String description;
  final String youtubeUrl;
  final String thumbnailUrl;
  final DateTime uploadDate;
  final bool isDefault;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.uploadDate,
    this.isDefault = false,
  });

  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      youtubeUrl: data['youtubeUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      uploadDate: data['uploadDate'] != null
          ? (data['uploadDate'] as Timestamp).toDate()
          : DateTime.now(),
      isDefault: data['isDefault'] ?? false,
    );
  }
}
