import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agribot/services/api_service.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  File? _image;
  String? _prediction;
  bool _isPredicting = false;
  final ApiService _apiService = ApiService();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _prediction = null;
      });
      _predictImage();
    }
  }

  Future<void> _predictImage() async {
    if (_image == null) return;

    setState(() {
      _isPredicting = true;
    });

    try {
      final result = await _apiService.predictDisease(_image!);
      setState(() {
        _prediction =
            "${result['prediction']} (${result['confidence']}% confidence)";
      });
    } catch (e) {
      setState(() {
        _prediction = "Error during prediction: $e";
      });
    } finally {
      setState(() {
        _isPredicting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Text('Disease Detection', textAlign: TextAlign.center),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : Text('No image selected'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showImageSourceDialog(context),
              child: Text('Select Image'),
            ),
            SizedBox(height: 10),
            if (_isPredicting)
              CircularProgressIndicator()
            else if (_prediction != null)
              Text('Prediction: $_prediction'),
          ],
        ),
      ),
    );
  }

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
