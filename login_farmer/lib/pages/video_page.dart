import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPage extends StatefulWidget {
  final String videoURL;

  const VideoPage({super.key, required this.videoURL});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late YoutubePlayerController playerController;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoURL);
    if (videoId == null) {
      // Handle error appropriately
      playerController = YoutubePlayerController(
        initialVideoId:
            'uVH2ri13rhw?si=mxBgc7FiUz8YMWpa', // Provide a default or placeholder video ID
        flags: const YoutubePlayerFlags(autoPlay: false),
      );
    } else {
      playerController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false),
      );
    }
  }

  @override
  void dispose() {
    playerController.dispose(); // Dispose the controller
    super.dispose();
  }

  void seekForward() {
    final currentPosition = playerController.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    playerController.seekTo(newPosition);
  }

  void seekBackward() {
    final currentPosition = playerController.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    playerController.seekTo(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF375534),
        foregroundColor: Colors.white,
        title: const Text("Video"),
      ),
      body: Stack(
        children: [
          YoutubePlayer(
            controller: playerController,
            showVideoProgressIndicator: true,
            onReady: () {
              // Video is ready to play
            },
            onEnded: (metaData) {
              print('Video ended');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video ended')),
              );
            },
          ),
          Positioned(
            top: 100,
            right: 100,
            left: 100,
            bottom: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: seekBackward,
                  icon: const Icon(
                    Icons.replay_10,
                    size: 30,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(width: 30),
                IconButton(
                  onPressed: seekForward,
                  icon: const Icon(
                    Icons.forward_10,
                    size: 30,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
