import 'package:login_farmer/main.dart';
import 'package:login_farmer/models/video_model.dart';
import 'package:login_farmer/service/api_service.dart';

class VideoService {
  final ApiService _apiService = getIt<ApiService>();

  /// Fetch all videos
  Future<List<VideoModel>> getVideos() async {
    try {
      final result = await _apiService.getVideos();

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> videosJson =
            result['data']['data']; // assuming paginated
        return videosJson.map((json) => VideoModel.fromJson(json)).toList();
      } else {
        throw Exception(result['message'] ?? 'Failed to fetch videos');
      }
    } catch (e) {
      throw Exception('Error fetching videos: $e');
    }
  }

  /// Fetch video by ID
  Future<VideoModel> getVideoDetails(int videoId) async {
    try {
      final result = await _apiService.getVideoDetails(videoId);

      if (result['success'] == true && result['data'] != null) {
        return VideoModel.fromJson(result['data']);
      } else {
        throw Exception(result['message'] ?? 'Failed to fetch video details');
      }
    } catch (e) {
      throw Exception('Error fetching video details: $e');
    }
  }
}
