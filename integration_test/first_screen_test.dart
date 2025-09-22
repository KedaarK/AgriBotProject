import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agribot/test_main.dart' as test_app; // Use the lightweight main

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FirstScreen navigation to LoginScreen',
      (WidgetTester tester) async {
    test_app.main(); // ✅ Launch without Firebase
    await tester.pumpAndSettle();

    final signInButton = find.byKey(const Key('SignInButton'));
    expect(signInButton, findsOneWidget, reason: 'SignInButton not found');

    await tester.tap(signInButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final welcomeBackText = find.text('Welcome Back');
    expect(welcomeBackText, findsOneWidget,
        reason: 'LoginScreen did not appear');
  });
}
