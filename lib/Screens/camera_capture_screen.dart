import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:url_launcher/url_launcher.dart';

class CameraCaptureScreen extends StatefulWidget {
  @override
  _CameraCaptureScreenState createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  File? _imageFile;
  String? _qrResult;

  // Initialize BarcodeScanner instance
  final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  Future<void> captureImage() async {
    final String flaskUrl =
        "http://192.168.96.84:8080/capture"; // Replace with actual IP

    try {
      var response = await http.get(Uri.parse(flaskUrl));

      if (response.statusCode == 200) {
        final Directory tempDir = await getTemporaryDirectory();
        final File imageFile = File('${tempDir.path}/captured_image.jpg');
        await imageFile.writeAsBytes(response.bodyBytes);

        setState(() {
          _imageFile = imageFile;
        });

        // Process the captured image for QR code or leaf disease detection
        await processImage(imageFile);
      } else {
        print("Failed to capture image: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // Process image to detect QR code or pass it for disease detection
  Future<void> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final qrCode = barcodes.first.rawValue ?? '';
        setState(() {
          _qrResult = qrCode;
        });

        // If QR code found, launch the URL
        if (await canLaunch(qrCode)) {
          await launch(qrCode);
        } else {
          print("Could not launch the URL.");
        }
      } else {
        print("No QR code detected.");
        // If no QR code, proceed with plant disease detection
        await processLeafImage(imageFile);
      }
    } catch (e) {
      print("Error processing image: $e");
      // If QR code scanning fails, attempt plant disease detection
      await processLeafImage(imageFile);
    }
  }

  // Function to process the image as a leaf for plant disease detection
  Future<void> processLeafImage(File imageFile) async {
    try {
      final String flaskUrl = "http://192.168.96.84:8080/detect_plant_disease"; // Flask URL for plant disease detection

      var request = http.MultipartRequest('POST', Uri.parse(flaskUrl));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        print("Plant disease prediction success!");
        // Process the response for disease details (e.g., treatment advice)
      } else {
        print("Failed to predict plant disease: ${response.statusCode}");
      }
    } catch (e) {
      print("Error processing leaf image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Camera Capture")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile == null
                ? Text("Press the button to capture an image")
                : Image.file(_imageFile!),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: captureImage,
              child: Text("Capture Image"),
            ),
            if (_qrResult != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("QR Code URL: $_qrResult"),
              ),
          ],
        ),
      ),
    );
  }
}
