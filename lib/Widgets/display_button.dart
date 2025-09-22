import 'package:flutter/material.dart';

class DisplayButton extends StatelessWidget {
  const DisplayButton({
    required this.text,
    required this.onTap,
    required this.bgColor,
    required this.radius,
    this.buttonKey, // ✅ renamed to avoid conflict with Widget key
  });

  final Color bgColor;
  final String text;
  final void Function() onTap;
  final double radius;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth / 375.0;

    return ElevatedButton(
      key: buttonKey, // ✅ This is now explicit and avoids collision
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: 12 * scale,
          horizontal: 132 * scale,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius * scale),
        ),
        textStyle: TextStyle(
          fontSize: 20 * scale,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Text(text),
    );
  }
}
