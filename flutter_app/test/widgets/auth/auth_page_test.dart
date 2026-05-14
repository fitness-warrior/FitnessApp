import 'package:fitness_app_flutter/views/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Widgets Tests', () {
    testWidgets('Login form renders all fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPage(),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
    });

    testWidgets('Invalid email shows validation error on login',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPage(),
        ),
      );

      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'myemail');
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('Registration form renders all required fields',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPage(),
        ),
      );

      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
    });

    testWidgets('Password field obscures text on signup', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthPage(),
        ),
      );

      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      final passwordField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.hintText == 'Password',
        ),
      );

      expect(passwordField.obscureText, isTrue);
    });
  });
}
