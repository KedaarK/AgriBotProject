import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agribot/main.dart' as app;

void main() {
  // Initialize integration test binding.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete Registration Screen Workflow Test',
      (WidgetTester tester) async {
    // Launch the app.
    app.main();
    await tester.pumpAndSettle(
        const Duration(seconds: 3)); // Wait for app initialization

    // Optionally navigate to the registration screen if the home screen displays a link.
    final createAccountLink = find.byKey(const Key('CreateAccountLink'));
    if (createAccountLink.evaluate().isNotEmpty) {
      await tester.tap(createAccountLink);
      await tester.pumpAndSettle(
          const Duration(seconds: 3)); // Wait for registration screen
    } else {
      print("Create Account link not found");
    }

    // Fill in the registration details.
    final nameField = find.byKey(const Key('NameField'));
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Test User');

    final emailField = find.byKey(const Key('EmailField'));
    expect(emailField, findsOneWidget);
    await tester.enterText(emailField, 'test@example.com');

    final sendOtpButton = find.byKey(const Key('SendOtpButton'));
    expect(sendOtpButton, findsOneWidget);
    await tester.tap(sendOtpButton);
    await tester.pumpAndSettle(
        const Duration(seconds: 10)); // Adjust time for network delay

    expect(find.textContaining("OTP"), findsWidgets);

    final otpField = find.byKey(const Key('OtpField'));
    expect(otpField, findsOneWidget);
    await tester.enterText(otpField, '123456');

    final verifyOtpButton = find.byKey(const Key('VerifyOtpButton'));
    expect(verifyOtpButton, findsOneWidget);
    await tester.tap(verifyOtpButton);
    await tester.pumpAndSettle(
        const Duration(seconds: 5)); // Increased wait time for OTP verification

    expect(find.textContaining("OTP Verified"), findsOneWidget);

    final passwordField = find.byKey(const Key('PasswordField'));
    expect(passwordField, findsOneWidget);
    await tester.enterText(passwordField, 'password123');

    final confirmPasswordField = find.byKey(const Key('ConfirmPasswordField'));
    expect(confirmPasswordField, findsOneWidget);
    await tester.enterText(confirmPasswordField, 'password123');

    final roleDropdown = find.byKey(const Key('RoleDropdown'));
    expect(roleDropdown, findsOneWidget);

    // Open the dropdown and wait for the options to load
    await tester.tap(roleDropdown);
    await tester.pumpAndSettle(
        const Duration(seconds: 3)); // Allow dropdown options to appear

    // Check if the dropdown contains the options
    final agronomistOption =
        find.text('Agronomist').first; // Use `.first` to target the first match
    final farmerOption =
        find.text('Farmer').first; // Use `.first` to target the first match
    expect(agronomistOption, findsOneWidget);
    expect(farmerOption, findsOneWidget);

    // Select 'Agronomist' role
    await tester.tap(agronomistOption);
    await tester.pumpAndSettle();

    final registerButton = find.byKey(const Key('RegisterSubmitButton'));
    expect(registerButton, findsOneWidget);
    await tester.tap(registerButton);
    await tester.pumpAndSettle(
        const Duration(seconds: 3)); // Wait for registration action

    // **STOP TEST HERE** after Register button is clicked.
    // Do not proceed with further UI checks after this point.
    // The test stops right after clicking Register button.
  });
}
