import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agribot/services/api_service.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:url_launcher/url_launcher.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  _DiseaseDetectionScreenState createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  File? _image;
  String? _prediction;
  String? _qrLink;
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();
  final BarcodeScanner _barcodeScanner =
      BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _prediction = null;
        _qrLink = null;
      });
      await _processImage();
    }
  }

  // Process image to detect QR code or predict disease
  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(_image!.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final qr = barcodes.first.rawValue ?? '';
        setState(() {
          _qrLink = qr;
          _isProcessing = false;
        });
      } else {
        final result = await _apiService.predictDisease(_image!);
        setState(() {
          _prediction =
              "${result['prediction']} (${result['confidence']}% confidence)";
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _prediction = "Error: $e";
        _isProcessing = false;
      });
    }
  }

  // Handle the display of image or prediction result
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('Disease Detection'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: size.height * 0.03, horizontal: padding),
          child: Center(
            child: Column(
              children: [
                Text(
                  'Upload Leaf / QR Image',
                  style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800]),
                ),
                SizedBox(height: size.height * 0.03),
                _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          width: size.width * 0.8,
                          height: size.height * 0.35,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text('No image selected',
                        style: TextStyle(fontSize: size.width * 0.045)),
                SizedBox(height: size.height * 0.03),
                ElevatedButton(
                  onPressed: () => _showImageSourceDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text('Select Image',
                        style: TextStyle(
                            fontSize: size.width * 0.045, color: Colors.white)),
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                if (_isProcessing) CircularProgressIndicator(),

                // Display QR Code or Prediction Result
                if (_qrLink != null)
                  Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Column(
                      children: [
                        Text('QR Code Detected:',
                            style: TextStyle(
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: size.height * 0.01),
                        GestureDetector(
                          onTap: () async {
                            String url = _qrLink!;
                            if (!url.startsWith('http')) {
                              url = "https://$url"; // add https if missing
                            }
                            final Uri uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Could not launch $url')));
                            }
                          },
                          child: Text(
                            _qrLink!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: size.width * 0.04),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_prediction != null)
                  Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Text(
                      'Prediction: $_prediction',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: size.width * 0.045,
                          color: Colors.green[700]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show bottom sheet for selecting image source (camera or gallery)
  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
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
}
