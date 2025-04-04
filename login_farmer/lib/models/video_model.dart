class VideoModel {
  final int id;
  final String title;
  final String description;
  final String url;
  final String createdAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      url: json['url'],
      createdAt: json['created_at'],
    );
  }

  // Helper to get YouTube video ID
  String? get youtubeId {
    RegExp regExp = RegExp(
      r"(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})",
    );
    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Get YouTube thumbnail URL
  String get thumbnailUrl {
    final id = youtubeId;
    if (id != null) {
      return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    return 'https://via.placeholder.com/480x360?text=Video';
  }
}
