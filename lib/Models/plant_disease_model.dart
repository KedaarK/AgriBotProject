// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
// // import 'dart:math' as math; // Import for math functions

// class PlantDiseaseModel {
//   Interpreter? _interpreter;
//   List<String> _labels = [];
//   static const int INPUT_SIZE = 128;

//   // Getter for the interpreter
//   Interpreter? get interpreter => _interpreter;

//   Future<void> loadModel() async {
//     try {
//       // Check if file exists first
//       final modelFile = await rootBundle
//           .load('assets/tflite/plant_disease_model_basic.tflite');
//       print('Model file size: ${modelFile.lengthInBytes} bytes');

//       _interpreter = await Interpreter.fromAsset(
//           'assets/tflite/plant_disease_model_basic.tflite');
//       print('Interpreter loaded successfully');

//       _labels = await _loadLabels();
//       print("Labels loaded: ${_labels.length} labels");
//     } catch (e) {
//       print('Error loading model or labels: $e');
//       // Print stack trace for more info
//       print(StackTrace.current);
//     }
//   }

//   Future<List<String>> _loadLabels() async {
//     try {
//       final String labelString =
//           await rootBundle.loadString("assets/tflite/labels.txt");
//       return labelString.split('\n');
//     } catch (e) {
//       print("Error loading labels: $e");
//       return <String>[];
//     }
//   }

//   Float32List imageToByteListFloat32(img.Image image, int inputSize) {
//     var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
//     var buffer = Float32List.view(convertedBytes.buffer);
//     int pixelIndex = 0;

//     for (int i = 0; i < inputSize; i++) {
//       for (int j = 0; j < inputSize; j++) {
//         img.Pixel pixel = image.getPixel(j, i);
//         buffer[pixelIndex++] = pixel.r / 255.0;
//         buffer[pixelIndex++] = pixel.g / 255.0;
//         buffer[pixelIndex++] = pixel.b / 255.0;
//       }
//     }
//     return convertedBytes;
//   }

//   Future<String> predict(Uint8List imageBytes) async {
//     if (_interpreter == null) {
//       return "Model not loaded yet!";
//     }

//     img.Image? resizedImage = img.decodeImage(imageBytes);
//     if (resizedImage == null) {
//       return "Failed to decode image";
//     }

//     img.Image resized =
//         img.copyResize(resizedImage, width: INPUT_SIZE, height: INPUT_SIZE);

//     var input = imageToByteListFloat32(resized, INPUT_SIZE);
//     var reshapedInput = input.reshape([1, INPUT_SIZE, INPUT_SIZE, 3]);

//     // Prepare output buffer
//     List<List<double>> output =
//         List.generate(1, (index) => List.filled(_labels.length, 0.0));

//     // Run inference
//     _interpreter!.run(reshapedInput, output);

//     // Get the predicted label
//     int index = output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));
//     String label = _labels[index];
//     return label;
//   }
// }
