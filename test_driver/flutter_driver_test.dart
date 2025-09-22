import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  late FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect(); // Connect to the Flutter app
  });

  tearDownAll(() async {
    if (driver != null) {
      await driver.close(); // Close the driver when done
    }
  });

  test('verify app has a register button', () async {
    final registerButton =
        find.byValueKey('registerButtonKey'); // Locate the button by key
    await driver.tap(registerButton); // Tap the button

    final nextScreen = find.byValueKey('nextScreenKey');
    expect(await driver.getText(nextScreen), 'Next Screen'); // Verify text
  });
}
