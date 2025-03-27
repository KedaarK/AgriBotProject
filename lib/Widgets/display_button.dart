import 'package:flutter/material.dart';

class DisplayButton extends StatelessWidget {
  const DisplayButton(
      {super.key,
      required this.text,
      required this.onTap,
      required this.bgColor,
      required this.radius});
  final Color bgColor;
  final String text;
  final void Function() onTap;
  final double radius;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 132),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        textStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Text(text),
    );
  }
}
