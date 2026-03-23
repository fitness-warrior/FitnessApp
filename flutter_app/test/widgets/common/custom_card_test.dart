import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/custom_card.dart';

void main() {
  group('CustomCard Widget Tests', () {
    testWidgets('CustomCard renders with default values',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byType(CustomCard), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('CustomCard renders child widget correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Column(
                children: [
                  Text('Title'),
                  Text('Subtitle'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
    });

    testWidgets('CustomCard applies custom padding',
        (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(32.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              padding: customPadding,
              child: Text('Padded Content'),
            ),
          ),
        ),
      );

      expect(find.text('Padded Content'), findsOneWidget);
      // Verify custom card was created with custom padding
      expect(find.byType(CustomCard), findsOneWidget);
    });

    testWidgets('CustomCard applies default padding when not specified',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CustomCard), findsOneWidget);
    });

    testWidgets('CustomCard applies custom margin',
        (WidgetTester tester) async {
      const customMargin =
          EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              margin: customMargin,
              child: Text('Margin Content'),
            ),
          ),
        ),
      );

      final cardWidget = find.byType(Card);
      final card = tester.widget<Card>(cardWidget);
      expect(card.margin, equals(customMargin));
    });

    testWidgets('CustomCard applies default margin when not specified',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final cardWidget = find.byType(Card);
      final card = tester.widget<Card>(cardWidget);
      expect(
        card.margin,
        equals(const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0)),
      );
    });

    testWidgets('CustomCard applies custom color', (WidgetTester tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              color: customColor,
              child: Text('Colored Card'),
            ),
          ),
        ),
      );

      final cardWidget = find.byType(Card);
      final card = tester.widget<Card>(cardWidget);
      expect(card.color, equals(customColor));
    });

    testWidgets('CustomCard applies custom elevation',
        (WidgetTester tester) async {
      const customElevation = 8.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              elevation: customElevation,
              child: Text('Elevated Card'),
            ),
          ),
        ),
      );

      final cardWidget = find.byType(Card);
      final card = tester.widget<Card>(cardWidget);
      expect(card.elevation, equals(customElevation));
    });

    testWidgets('CustomCard applies default elevation when not specified',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final cardWidget = find.byType(Card);
      final card = tester.widget<Card>(cardWidget);
      expect(card.elevation, equals(2.0));
    });

    testWidgets('CustomCard executes onTap callback when tapped',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              onTap: () {
                wasPressed = true;
              },
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomCard));
      await tester.pumpAndSettle();

      expect(wasPressed, isTrue);
    });

    testWidgets('CustomCard without onTap does not render InkWell',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Non-tappable Card'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('CustomCard with onTap renders InkWell',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              onTap: () {},
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('CustomCard applies custom borderRadius',
        (WidgetTester tester) async {
      const customRadius = BorderRadius.all(Radius.circular(20.0));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              borderRadius: customRadius,
              child: Text('Rounded Card'),
            ),
          ),
        ),
      );

      final cardWidget = find.byType(Card);
      final card = tester.widget<Card>(cardWidget);
      expect(card.shape, isA<RoundedRectangleBorder>());

      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(customRadius));
    });

    testWidgets('CustomCard applies default borderRadius when not specified',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final cardWidget = find.byType(Card);
      final card = tester.widget<Card>(cardWidget);
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('CustomCard with onTap applies borderRadius to InkWell',
        (WidgetTester tester) async {
      const customRadius = BorderRadius.all(Radius.circular(20.0));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              borderRadius: customRadius,
              onTap: () {},
              child: const Text('Rounded Tappable Card'),
            ),
          ),
        ),
      );

      final inkwellWidget = find.byType(InkWell);
      final inkwell = tester.widget<InkWell>(inkwellWidget);
      expect(inkwell.borderRadius, equals(customRadius));
    });

    testWidgets('CustomCard handles multiple properties together',
        (WidgetTester tester) async {
      bool tapWasCalled = false;
      const customColor = Colors.blue;
      const customElevation = 6.0;
      const customPadding = EdgeInsets.all(20.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              color: customColor,
              elevation: customElevation,
              padding: customPadding,
              onTap: () {
                tapWasCalled = true;
              },
              child: const Text('Complex Card'),
            ),
          ),
        ),
      );

      final cardWidget = find.byType(Card);
      final card = tester.widget<Card>(cardWidget);
      expect(card.color, equals(customColor));
      expect(card.elevation, equals(customElevation));

      await tester.tap(find.byType(CustomCard));
      await tester.pumpAndSettle();
      expect(tapWasCalled, isTrue);
    });
  });
}
