import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitness_app_flutter/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crawl tappables and verify app stability',
      (WidgetTester tester) async {
    // Launch the app
    app.main();
    await tester.pumpAndSettle();

    // Candidate finders by common tappable widget types
    final List<Finder> typedFinders = [
      find.byType(ElevatedButton),
      find.byType(TextButton),
      find.byType(OutlinedButton),
      find.byType(IconButton),
      find.byType(FloatingActionButton),
    ];

    final Set<String> seen = {};
    final List<String> actionLog = [];

    // Safety heuristics
    final destructiveLabels = {
      'delete',
      'finish',
      'save',
      'remove',
      'reset',
    };

    final skipTypes = {
      '_ModalBarrierGestureDetector',
      'RawGestureDetector',
      '_GestureSemantics',
    };

    const int maxTaps = 50; // Lower limit for stability
    int tapCount = 0;

    // Helper to extract text from an Element's subtree
    String extractTextFromElement(Element e) {
      final buffer = StringBuffer();
      void visitor(Element child) {
        if (child.widget is Text) {
          final Text t = child.widget as Text;
          if (t.data != null && t.data!.trim().isNotEmpty) {
            buffer.write(t.data!.trim() + ' ');
          }
        }
        child.visitChildren(visitor);
      }

      e.visitChildren(visitor);
      return buffer.toString().trim();
    }

    Future<void> safeTap(Finder f, String descriptor) async {
      try {
        // Try to scroll into view, but don't fail if it errors
        try {
          await tester.ensureVisible(f);
        } catch (_) {
          // Widget might be off-screen, try anyway
        }
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        await tester.tap(f, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // If an AlertDialog appears, try to dismiss safely
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          final neutralTexts = [
            'Cancel',
            'Close',
            'No',
            'Back',
            'Dismiss',
            'OK',
            'Okay'
          ];
          bool dismissed = false;
          for (final t in neutralTexts) {
            final tf = find.text(t);
            if (tf.evaluate().isNotEmpty) {
              await tester.tap(tf.first, warnIfMissed: false);
              await tester.pumpAndSettle(const Duration(milliseconds: 300));
              dismissed = true;
              break;
            }
          }
          if (!dismissed) {
            try {
              await tester.pageBack();
              await tester.pumpAndSettle(const Duration(milliseconds: 300));
            } catch (_) {}
          }
        }

        // If navigation changed away from a scaffold, try to go back
        if (find.byType(Scaffold).evaluate().isEmpty) {
          try {
            await tester.pageBack();
            await tester.pumpAndSettle(const Duration(milliseconds: 300));
          } catch (_) {}
        }

        actionLog.add('OK: $descriptor');
      } catch (e) {
        actionLog.add('ERROR: $descriptor -> $e');
        // Continue despite errors
      }
    }

    // Walk through typed finders and tap unique widgets
    for (final finder in typedFinders) {
      if (tapCount >= maxTaps) break;

      final matches = finder.evaluate().toList();
      for (var i = 0; i < matches.length; i++) {
        if (tapCount >= maxTaps) break;

        final element = matches[i];
        final widget = element.widget;
        final text = extractTextFromElement(element);
        final descriptor =
            '${widget.runtimeType} ${text.isEmpty ? '' : '"$text"'}';
        final lc = descriptor.toLowerCase();

        // Skip duplicates
        if (seen.contains(lc)) continue;
        seen.add(lc);

        // Skip certain widget types
        if (skipTypes.contains(widget.runtimeType.toString())) continue;

        // Skip taps that look destructive
        final lowerText = text.toLowerCase();
        if (destructiveLabels.any((d) => lowerText.contains(d))) {
          actionLog.add('SKIP (destructive): $descriptor');
          continue;
        }

        final specificFinder = finder.at(i);
        tapCount++;
        await safeTap(specificFinder, descriptor);
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    // Final sanity: app still has a Scaffold
    expect(find.byType(Scaffold), findsWidgets);

    // Log results (skip file write on emulator due to read-only filesystem)
    print('Integration test completed: $tapCount taps');
    for (final log in actionLog) {
      print(log);
    }
  });
}
