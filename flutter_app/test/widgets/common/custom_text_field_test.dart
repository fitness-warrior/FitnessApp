import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/widgets/common/custom_text_field.dart';

void main() {
  group('CustomTextField Widget Tests', () {

    testWidgets('Test 1: Text input binds to controller', (WidgetTester tester) async {
      // CustomTextField rendered with a TextEditingController
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              labelText: 'Name',
            ),
          ),
        ),
      );

      // User types 'Hello'
      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.pump();

      // Controller value updates to Hello
      expect(controller.text, equals('Hello'));

      controller.dispose();
    });

    testWidgets('Test 2: Label and hint text display correctly', (WidgetTester tester) async {
      // CustomTextField rendered with label 'email' and hint 'enter your email'
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'email',
              hintText: 'enter your email',
            ),
          ),
        ),
      );

      // Label 'email' and hint 'enter your email' both visible
      expect(find.text('email'), findsOneWidget);
      expect(find.text('enter your email'), findsOneWidget);
    });

    testWidgets('Test 3: Validation error message displays', (WidgetTester tester) async {
      // CustomTextField rendered with errorText: 'email is required'
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'email',
              errorText: 'email is required',
            ),
          ),
        ),
      );

      // 'email is required' error text is visible below the field
      expect(find.text('email is required'), findsOneWidget);
    });

    testWidgets('Test 4: Password field obscures text', (WidgetTester tester) async {
      // CustomTextField rendered with obscureText: true
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      // User types 'pass145'
      await tester.enterText(find.byType(TextFormField), 'pass145');
      await tester.pump();

      // Text is obscured and not readable on screen
      // Check via the underlying EditableText which exposes obscureText
      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
    });

  });
}
