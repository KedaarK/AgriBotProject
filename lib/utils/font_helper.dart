import 'package:flutter/material.dart';

class FontHelper {
  static TextStyle getStyle(
      {required Color textColor,
      required double fontSize,
      required FontWeight fontWeight}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: textColor,
      height: 0,
    );
  }
}
