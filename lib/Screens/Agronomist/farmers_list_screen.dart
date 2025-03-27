import 'package:flutter/material.dart';

class FarmersListScreen extends StatelessWidget {
  const FarmersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text("Farmer ${index + 1}"),
            subtitle: const Text("Crop: Wheat"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to Farmer Profile
            },
          ),
        );
      },
    );
  }
}
