import 'package:flutter/material.dart';

class IconButtonRow extends StatelessWidget {
  final bool up;
  final bool down;
  final bool left;
  final bool right;

  const IconButtonRow({
    super.key,
    this.up = false,
    this.down = false,
    this.left = false,
    this.right = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (left) MovementButton(icon: Icons.arrow_back),
        if (up) MovementButton(icon: Icons.arrow_upward),
        if (right) MovementButton(icon: Icons.arrow_forward),
        if (down) MovementButton(icon: Icons.arrow_downward),
      ],
    );
  }
}

// Reusable movement button widget
class MovementButton extends StatelessWidget {
  final IconData icon;

  const MovementButton({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Add movement logic here
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700], // Background color
        padding: EdgeInsets.all(24.0),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
