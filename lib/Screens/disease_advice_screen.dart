// disease_advice_screen.dart
import 'package:flutter/material.dart';

class DiseaseAdviceScreen extends StatelessWidget {
  final Map<String, dynamic> advice;
  final String title;
  const DiseaseAdviceScreen(
      {super.key, required this.advice, required this.title});

  Widget _bullets(List items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map<Widget>((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• "),
                      Expanded(child: Text(e.toString())),
                    ],
                  ),
                ))
            .toList(),
      );

  @override
  Widget build(BuildContext context) {
    final s = advice;
    return Scaffold(
      appBar: AppBar(title: Text('Advice — $title')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (s['summary'] != null) ...[
            Text(s['summary'],
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
          ],
          if (s['cultural_practices'] != null) ...[
            const Text('Cultural practices',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _bullets(List.from(s['cultural_practices'])),
            const SizedBox(height: 12),
          ],
          if (s['sanitation_practices'] != null) ...[
            const Text('Sanitation practices',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _bullets(List.from(s['sanitation_practices'])),
            const SizedBox(height: 12),
          ],
          if (s['resistant_varieties'] != null) ...[
            const Text('Resistant varieties',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _bullets(List.from(s['resistant_varieties'])),
            const SizedBox(height: 12),
          ],
          if (s['monitoring'] != null) ...[
            const Text('Monitoring',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _bullets(List.from(s['monitoring'])),
            const SizedBox(height: 12),
          ],
          if (s['disclaimer'] != null)
            Text(s['disclaimer'], style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
