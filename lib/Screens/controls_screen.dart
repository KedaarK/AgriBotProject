import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  late final WebViewController _controller; // Ensure late initialization
  bool _isIpAvailable = false; // Track if IP is available

  final String botControlUrl = "http://192.168.1.53/"; // Replace with actual IP
  final String youtubeVideoUrl =
      "https://www.youtube.com/watch?v=v85j1pIjMiQ"; // Replace with your video URL

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkIpAvailability();
  }

  // Check if the IP is reachable
  Future<void> _checkIpAvailability() async {
    try {
      final response = await http.get(Uri.parse(botControlUrl));
      if (response.statusCode == 200) {
        setState(() {
          _isIpAvailable = true;
        });
      } else {
        setState(() {
          _isIpAvailable = false;
        });
      }
    } catch (e) {
      setState(() {
        _isIpAvailable = false;
      });
      print("Error checking IP availability: $e");
    }
  }

  // Initialize the WebView controller
  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  // Build the WebView or message based on IP availability
  Widget _buildWebView() {
    if (_isIpAvailable) {
      _controller.loadRequest(
          Uri.parse(botControlUrl)); // Load bot control URL if IP is available
      return WebViewWidget(controller: _controller);
    } else {
      // If IP is not available, show the YouTube video instead
      _controller.loadRequest(Uri.parse(youtubeVideoUrl));
      return WebViewWidget(controller: _controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text("AgriBot Controls"),
      ),
      body: Center(
        child: _isIpAvailable == null
            ? const CircularProgressIndicator() // Show loading indicator while checking IP
            : _buildWebView(),
      ),
    );
  }
}
