import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agribot/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Performance test - app startup and interaction',
      (WidgetTester tester) async {
    final Stopwatch startupStopwatch = Stopwatch()..start();

    app.main();

    // Wait for full UI load
    await tester.pumpAndSettle(const Duration(seconds: 3));

    startupStopwatch.stop();
    print('🟢 App startup time: ${startupStopwatch.elapsedMilliseconds}ms');

    // Add another pump just in case background image or fonts cause layout delay
    await tester.pump(const Duration(seconds: 1));

    // Try to find the "Create Account" link
    final createAccountLink = find.byKey(const Key('CreateAccountLink'));
    expect(createAccountLink, findsOneWidget); // <== still required

    final Stopwatch interactionStopwatch = Stopwatch()..start();
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    interactionStopwatch.stop();
    print(
        '🟢 Navigation to RegisterScreen time: ${interactionStopwatch.elapsedMilliseconds}ms');

    expect(find.byKey(const Key('TitleRegister')), findsOneWidget);
  });
}