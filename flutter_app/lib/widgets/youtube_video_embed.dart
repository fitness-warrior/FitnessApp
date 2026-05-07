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
    final videoId = _extractYoutubeVideoId(widget.youtubeUrl);

    if (videoId == null || videoId.isEmpty) {
      _errorMessage = 'This video link is not a valid YouTube URL.';
      return;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
    );
  }

  String? _extractYoutubeVideoId(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    // Try package helper first.
    final direct = YoutubePlayerController.convertUrlToId(trimmed);
    if (direct != null && direct.isNotEmpty) return direct;

    // Accept links without protocol by prepending https.
    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'https://$trimmed';

    final fallback = YoutubePlayerController.convertUrlToId(withScheme);
    if (fallback != null && fallback.isNotEmpty) return fallback;

    final uri = Uri.tryParse(withScheme);
    if (uri == null) return null;

    // Common watch URL format: youtube.com/watch?v=VIDEO_ID
    final v = uri.queryParameters['v'];
    if (_isValidId(v)) return v;

    // Path-based formats: youtu.be/ID, /shorts/ID, /embed/ID, /live/ID
    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;

    if ((uri.host.contains('youtu.be') ||
            uri.host.contains('youtube.com') ||
            uri.host.contains('youtube-nocookie.com')) &&
        _isValidId(segments.last)) {
      return segments.last;
    }

    return null;
  }

  bool _isValidId(String? value) {
    if (value == null) return false;
    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value);
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
