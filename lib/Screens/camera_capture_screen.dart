// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;
// // import 'qr_result_screen.dart';

// class CameraCaptureScreen extends StatefulWidget {
//   const CameraCaptureScreen({Key? key}) : super(key: key);

//   @override
//   _CameraCaptureScreenState createState() => _CameraCaptureScreenState();
// }

// class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
//   File? _imageFile;
//   String? _qrResult;
//   String? _launchUrl;
//   final BarcodeScanner _barcodeScanner =
//       BarcodeScanner(formats: [BarcodeFormat.qrCode]);

//   /// Capture image from your Flask server.
//   Future<void> captureImage() async {
//     // Update with your Flask server URL for capturing image
//     final String flaskUrl = "http://192.168.96.84:8080/capture";

//     try {
//       final response = await http.get(Uri.parse(flaskUrl));
//       if (response.statusCode == 200) {
//         final Directory tempDir = await getTemporaryDirectory();
//         final File imageFile = File('${tempDir.path}/captured_image.jpg');
//         await imageFile.writeAsBytes(response.bodyBytes);
//         setState(() {
//           _imageFile = imageFile;
//         });
//         await processImage(imageFile);
//       } else {
//         print("Failed to capture image: ${response.statusCode}");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Failed to capture image: ${response.statusCode}"),
//           ),
//         );
//       }
//     } catch (e) {
//       print("Error capturing image: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error capturing image: $e")),
//       );
//     }
//   }

//   /// Process the image to detect a QR code.
//   Future<void> processImage(File imageFile) async {
//     try {
//       final inputImage = InputImage.fromFilePath(imageFile.path);
//       final barcodes = await _barcodeScanner.processImage(inputImage);
//       if (barcodes.isNotEmpty) {
//         final qrCode = barcodes.first.rawValue ?? '';
//         setState(() {
//           _qrResult = qrCode;
//         });

//         // Validate and prepare a URL (prepend "https://" if needed)
//         String url = qrCode;
//         if (!url.startsWith('http://') && !url.startsWith('https://')) {
//           url = "https://$url";
//         }
//         final uri = Uri.tryParse(url);
//         if (uri != null && uri.isAbsolute) {
//           setState(() {
//             _launchUrl = url;
//           });
//           // Navigate to QRResultScreen with the QR code result
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => null,
//             ),
//           );
//         }
//       } else {
//         print("No QR code detected.");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("No QR code detected. Processing as plant image."),
//           ),
//         );
//         await processLeafImage(imageFile);
//       }
//     } catch (e) {
//       print("Error processing image: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error processing image: $e")),
//       );
//       await processLeafImage(imageFile);
//     }
//   }

//   /// Process the image as a plant leaf image for disease detection.
//   Future<void> processLeafImage(File imageFile) async {
//     // Update with your Flask URL for plant disease detection
//     final String flaskUrl = "http://192.168.96.84:8080/detect_plant_disease";
//     try {
//       var request = http.MultipartRequest('POST', Uri.parse(flaskUrl));
//       request.files
//           .add(await http.MultipartFile.fromPath('image', imageFile.path));
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         print("Plant disease prediction success!");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Plant disease prediction success!")),
//         );
//       } else {
//         print("Failed to predict plant disease: ${response.statusCode}");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text(
//                   "Failed to predict plant disease: ${response.statusCode}")),
//         );
//       }
//     } catch (e) {
//       print("Error processing leaf image: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error processing leaf image: $e")),
//       );
//     }
//   }

//   /// Pick an image from the gallery.
//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await ImagePicker().pickImage(source: source);
//     if (pickedFile != null) {
//       final file = File(pickedFile.path);
//       setState(() {
//         _imageFile = file;
//       });
//       await processImage(file);
//     }
//   }

//   /// Show bottom sheet with options to capture or select an image.
//   void _showImageSourceDialog() {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Take a picture'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   captureImage();
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Choose from gallery'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _pickImage(ImageSource.gallery);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   /// Redirect to the URL if available.
//   Future<void> _redirectToUrl() async {
//     if (_launchUrl != null) {
//       final uri = Uri.parse(_launchUrl!);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not launch $_launchUrl')),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _barcodeScanner.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final double padding = size.width * 0.05;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Camera Capture"),
//         backgroundColor: Colors.green[800],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(
//             vertical: size.height * 0.03,
//             horizontal: padding,
//           ),
//           child: Center(
//             child: Column(
//               children: [
//                 Text(
//                   "Capture an Image for Crop Diagnosis or QR Scan",
//                   style: TextStyle(
//                     fontSize: size.width * 0.05,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green[900],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: size.height * 0.03),
//                 _imageFile == null
//                     ? Text(
//                         "Press the button to capture an image",
//                         style: TextStyle(fontSize: size.width * 0.045),
//                       )
//                     : ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Image.file(
//                           _imageFile!,
//                           width: size.width * 0.8,
//                           height: size.height * 0.4,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                 SizedBox(height: size.height * 0.03),
//                 ElevatedButton(
//                   onPressed: _showImageSourceDialog,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green[700],
//                     padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
//                   ),
//                   child: Text(
//                     "Capture or Upload Image",
//                     style: TextStyle(fontSize: size.width * 0.045),
//                   ),
//                 ),
//                 SizedBox(height: size.height * 0.02),
//                 if (_qrResult != null)
//                   Container(
//                     padding: EdgeInsets.all(size.width * 0.04),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           "QR Code Detected:",
//                           style: TextStyle(
//                             fontSize: size.width * 0.045,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: size.height * 0.01),
//                         Text(
//                           _qrResult!,
//                           style: TextStyle(
//                             fontSize: size.width * 0.04,
//                             color: Colors.green[700],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         SizedBox(height: size.height * 0.02),
//                         if (_launchUrl != null)
//                           ElevatedButton(
//                             onPressed: _redirectToUrl,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               padding: EdgeInsets.symmetric(
//                                 vertical: size.height * 0.015,
//                                 horizontal: size.width * 0.1,
//                               ),
//                             ),
//                             child: const Text("Redirect to Website"),
//                           ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
