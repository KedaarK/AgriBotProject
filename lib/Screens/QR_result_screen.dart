import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QRResultScreen extends StatelessWidget {
  final String result;

  const QRResultScreen({super.key, required this.result});

  // Function to validate if the result is a valid URL
  bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null && (uri.hasScheme && uri.isAbsolute);
  }

  // Function to launch the URL using the new 'launchUrl' method
  void _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrl = _isValidUrl(result);

    return Scaffold(
      appBar: AppBar(title: const Text('QR Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(result, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            // Only show the button if the result is a valid URL
            if (isUrl)
              ElevatedButton(
                onPressed: () => _launchUrl(context, result),
                child: const Text('Launch in Browser'),
              ),
          ],
        ),
      ),
    );
  }
}
