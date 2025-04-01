import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  late final WebViewController _controller;
  bool _isIpAvailable = false;
  bool _isLoading = true;

  final String botControlUrl = "http://192.168.1.53/"; // Replace with actual IP
  final String youtubeVideoUrl =
      "https://www.youtube.com/watch?v=v85j1pIjMiQ"; // Replace with your video URL

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkIpAvailability();
  }

  Future<void> _checkIpAvailability() async {
    try {
      final response = await http.get(Uri.parse(botControlUrl));
      if (response.statusCode == 200) {
        setState(() {
          _isIpAvailable = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isIpAvailable = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isIpAvailable = false;
        _isLoading = false;
      });
      print("Error checking IP availability: $e");
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  Widget _buildWebView(Size size) {
    if (_isIpAvailable) {
      _controller.loadRequest(Uri.parse(botControlUrl));
      return WebViewWidget(controller: _controller);
    } else {
      _controller.loadRequest(Uri.parse(youtubeVideoUrl));
      return WebViewWidget(controller: _controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text("AgriBot Controls"),
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Container(
                  width: size.width,
                  height: size.height * 0.85,
                  child: _buildWebView(size),
                ),
        ),
      ),
    );
  }
}
