import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://10.0.2.2:5000/api'; // Localhost/Ngrok URL

  // Crop Recommendation
  Future<Map<String, dynamic>> getCropRecommendation(
      Map<String, dynamic> formData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/crop_recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch recommendation');
    }
  }

  // Plant Disease Detection
  Future<Map<String, dynamic>> predictDisease(File imageFile) async {
    var uri = Uri.parse('$baseUrl/predict');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      return json.decode(responseData);
    } else {
      throw Exception('Failed to get prediction');
    }
  }
}
