import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitness_app_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Meal plan page smoke test', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Just verify the app starts
    expect(find.byType(app.MyApp), findsOneWidget);
  });
}