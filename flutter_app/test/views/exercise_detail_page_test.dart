import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/views/exercise_detail_page.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class _TestWebViewPlatform extends WebViewPlatform {
  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return _TestNavigationDelegate(params);
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return _TestWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return _TestWebViewWidget(params);
  }
}

class _TestNavigationDelegate extends PlatformNavigationDelegate {
  _TestNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future<void>.value();
  }
}

class _TestWebViewController extends PlatformWebViewController {
  _TestWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    covariant PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async {}

  @override
  Future<void> addJavaScriptChannel(
      JavaScriptChannelParams javaScriptChannelParams) async {}

  @override
  Future<void> enableZoom(bool enabled) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async => '';

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future<void>.value();
  }
}

class _TestWebViewWidget extends PlatformWebViewWidget {
  _TestWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    WebViewPlatform.instance = _TestWebViewPlatform();
  });

  group('ExerciseDetailPage', () {
    final sampleExercise = {
      'name': 'Bench Press',
      'area': 'Chest',
      'type': 'Strength',
      'description': 'Press the bar from chest to lockout.',
      'equipment': ['Barbell'],
      'video': '',
    };

    testWidgets('renders exercise name in app bar and body', (tester) async {
      await tester
          .pumpWidget(_wrap(ExerciseDetailPage(exercise: sampleExercise)));
      await tester.pumpAndSettle();

      // Title is rendered in the sliver app bar and again in the page body.
      expect(find.text('Bench Press'), findsNWidgets(2));
    });

    testWidgets('area badge renders with correct label', (tester) async {
      await tester
          .pumpWidget(_wrap(ExerciseDetailPage(exercise: sampleExercise)));
      await tester.pumpAndSettle();

      // The badge text uses a specific accent colour for the area 'Chest'.
      final badgeFinder = find.byWidgetPredicate((w) {
        return w is Text &&
            w.data == 'Chest' &&
            w.style?.color == const Color(0xFFEF5350);
      });

      expect(badgeFinder, findsOneWidget);
    });

    testWidgets('type badge renders when type provided', (tester) async {
      await tester
          .pumpWidget(_wrap(ExerciseDetailPage(exercise: sampleExercise)));
      await tester.pumpAndSettle();

      expect(find.text('Strength'), findsNWidgets(2));
    });

    testWidgets('equipment information tile displays correctly',
        (tester) async {
      await tester
          .pumpWidget(_wrap(ExerciseDetailPage(exercise: sampleExercise)));
      await tester.pumpAndSettle();

      expect(find.text('Barbell'), findsOneWidget);
    });

    testWidgets(
        'renders empty exercise map without crashing and shows fallback text',
        (tester) async {
      await tester.pumpWidget(_wrap(const ExerciseDetailPage(exercise: {})));
      await tester.pumpAndSettle();

      expect(find.text('Unknown'), findsWidgets);
      expect(find.text('No description available.'), findsOneWidget);
    });

    testWidgets('legs area highlights all legs muscle groups in body diagram',
        (tester) async {
      final legsExercise = {
        'name': 'Squat',
        'area': 'Legs',
        'description': 'Leg-focused exercise.',
        'equipment': ['Barbell'],
        'video': '',
      };

      await tester
          .pumpWidget(_wrap(ExerciseDetailPage(exercise: legsExercise)));
      await tester.pumpAndSettle();

      final paints = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((paint) =>
              paint.painter != null &&
              paint.painter.runtimeType.toString() == '_BodyPainter')
          .toList();

      expect(paints.length, 2);

      for (final paint in paints) {
        final painter = paint.painter as dynamic;
        final highlights = (painter.highlights as List<dynamic>)
            .map((part) => part.toString())
            .toSet();

        expect(highlights.length, 4);
        expect(highlights.contains('_BodyPart.quads'), isTrue);
        expect(highlights.contains('_BodyPart.hamstrings'), isTrue);
        expect(highlights.contains('_BodyPart.calves'), isTrue);
        expect(highlights.contains('_BodyPart.glutes'), isTrue);
        expect(painter.accentColor, const Color(0xFF66BB6A));
      }
    });

    testWidgets('does not render video section when no video URL is available',
        (tester) async {
      final exerciseWithoutVideo = {
        'name': 'Lunge',
        'area': 'Legs',
        'type': 'Strength',
        'description': 'A lower-body exercise.',
        'equipment': ['Bodyweight'],
      };

      await tester.pumpWidget(
          _wrap(ExerciseDetailPage(exercise: exerciseWithoutVideo)));
      await tester.pumpAndSettle();

      expect(find.text('How to do it'), findsNothing);
    });

    testWidgets('renders video section when a valid URL is provided',
        (tester) async {
      final exerciseWithValidVideo = {
        'name': 'Lunge',
        'area': 'Legs',
        'type': 'Strength',
        'description': 'A lower-body exercise.',
        'equipment': ['Bodyweight'],
        'video': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      };

      await tester.pumpWidget(
        _wrap(ExerciseDetailPage(exercise: exerciseWithValidVideo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('How to do it'), findsOneWidget);
    });
  });
}
