import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:agribot/Screens/QR_result_screen.dart'; // Import the QRResultScreen

class CameraCaptureScreen extends StatefulWidget {
  @override
  _CameraCaptureScreenState createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  File? _imageFile;
  String? _qrResult;
  String? _launchUrl; // To store valid URL
  final BarcodeScanner _barcodeScanner =
      BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  // Capture Image from Camera
  Future<void> captureImage() async {
    final String flaskUrl =
        "http://192.168.96.84:8080/capture"; // Your Flask server URL

    try {
      var response = await http.get(Uri.parse(flaskUrl));

      if (response.statusCode == 200) {
        final Directory tempDir = await getTemporaryDirectory();
        final File imageFile = File('${tempDir.path}/captured_image.jpg');
        await imageFile.writeAsBytes(response.bodyBytes);

        setState(() {
          _imageFile = imageFile;
        });

        await processImage(imageFile);
      } else {
        print("Failed to capture image: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // Process the captured/uploaded image to detect QR code
  Future<void> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final qrCode = barcodes.first.rawValue ?? '';
        setState(() {
          _qrResult = qrCode;
        });

        // Prepare valid URL
        String url = qrCode;
        if (!url.startsWith('http') && !url.startsWith('https')) {
          url = "https://$url"; // Default to https://
        }

        final uri = Uri.tryParse(url);
        if (uri != null && uri.isAbsolute) {
          setState(() {
            _launchUrl = url;
          });

          // Navigate to the QRResultScreen if QR code is found
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRResultScreen(result: qrCode),
            ),
          );
        }
      } else {
        print("No QR code detected.");
        await processLeafImage(imageFile); // Handle plant leaf image
      }
    } catch (e) {
      print("Error processing image: $e");
      await processLeafImage(imageFile); // Handle plant leaf image
    }
  }

  // Process leaf image if no QR code is detected
  Future<void> processLeafImage(File imageFile) async {
    try {
      final String flaskUrl =
          "http://192.168.96.84:8080/detect_plant_disease"; // Flask URL

      var request = http.MultipartRequest('POST', Uri.parse(flaskUrl));
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        print("Plant disease prediction success!");
      } else {
        print("Failed to predict plant disease: ${response.statusCode}");
      }
    } catch (e) {
      print("Error processing leaf image: $e");
    }
  }

  // Show options for capturing image from Camera or Upload from Gallery
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  captureImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick an image from the gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await processImage(_imageFile!); // Process the picked image
    }
  }

  // Redirect to URL if QR code found
  void _redirectToUrl() async {
    if (_launchUrl != null) {
      final uri = Uri.parse(_launchUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $_launchUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: Text("Camera Capture"),
        backgroundColor: Colors.green[800],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: size.height * 0.03, horizontal: padding),
          child: Center(
            child: Column(
              children: [
                Text(
                  "Capture an Image for Crop Diagnosis or QR Scan",
                  style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.03),
                _imageFile == null
                    ? Text(
                        "Press the button to capture an image",
                        style: TextStyle(fontSize: size.width * 0.045),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFile!,
                          width: size.width * 0.8,
                          height: size.height * 0.4,
                          fit: BoxFit.cover,
                        ),
                      ),
                SizedBox(height: size.height * 0.03),
                ElevatedButton(
                  onPressed: _showImageSourceDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                  ),
                  child: Text(
                    "Capture or Upload Image",
                    style: TextStyle(fontSize: size.width * 0.045),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                if (_qrResult != null)
                  Container(
                    padding: EdgeInsets.all(size.width * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "QR Code Detected:",
                          style: TextStyle(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          _qrResult!,
                          style: TextStyle(
                              fontSize: size.width * 0.04,
                              color: Colors.green[700]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.02),
                        if (_launchUrl != null)
                          ElevatedButton(
                            onPressed: _redirectToUrl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: Text("Redirecting to Website"),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
