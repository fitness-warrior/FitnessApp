import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubeVideoEmbed extends StatefulWidget {
  final String youtubeUrl;

  const YoutubeVideoEmbed({
    Key? key,
    required this.youtubeUrl,
  }) : super(key: key);

  @override
  State<YoutubeVideoEmbed> createState() => _YoutubeVideoEmbedState();
}

class _YoutubeVideoEmbedState extends State<YoutubeVideoEmbed> {
  YoutubePlayerController? _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    final videoId = YoutubePlayerController.convertUrlToId(widget.youtubeUrl);

    if (videoId == null || videoId.isEmpty) {
      _errorMessage = 'This video link is not a valid YouTube URL.';
      return;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Text(
          _errorMessage!,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Text(
          'Video preview is unavailable for this link.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: YoutubePlayer(
        controller: controller,
        aspectRatio: 16 / 9,
        backgroundColor: const Color(0xFF1C1C2E),
        enableFullScreenOnVerticalDrag: false,
      ),
    );
  }
}
