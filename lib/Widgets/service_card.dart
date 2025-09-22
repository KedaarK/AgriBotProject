// service_card.dart
import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  const ServiceCard({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: service['onTap'] != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => service['onTap']()),
              );
            }
          : null,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  service['image'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ListTile(
              title: Text(
                service['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(service['subtitle']),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ],
        ),
      ),
    );
  }
}
