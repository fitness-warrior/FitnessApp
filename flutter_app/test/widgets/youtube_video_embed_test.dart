import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:fitness_app_flutter/widgets/youtube_video_embed.dart';

class _TestWebViewPlatform extends WebViewPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    WebViewPlatform.instance = _TestWebViewPlatform();
  });

  group('YoutubeVideoEmbed', () {
    testWidgets('Invalid URL shows error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YoutubeVideoEmbed(
              youtubeUrl: 'https://www.example.com/watch?v=invalid',
            ),
          ),
        ),
      );

      expect(find.byType(YoutubeVideoEmbed), findsOneWidget);
      expect(find.text('This video link is not a valid YouTube URL.'),
          findsOneWidget);
    });
  });
}
