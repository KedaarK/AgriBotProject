import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle; // Optional subtitle for extra info

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Use a reference width of 375.0 (common on many devices)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth / 375.0;

    return Card(
      color: const Color.fromARGB(255, 219, 229, 221),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      elevation: 4 * scale,
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              value,
              style: TextStyle(
                fontSize: 24 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: 4 * scale),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
