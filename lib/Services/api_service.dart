import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Point this at your Flask base (note the /api suffix based on your routes)
  // For Android emulator -> host machine, you can use: http://10.0.2.2:5000/api
  // final String baseUrl = 'http://10.210.119.19:5000/api';
  // final String rootUrl = 'http://10.210.119.119:5000';
  
  
  final String baseUrl = 'http://10.0.2.2:5000/api';
  final String rootUrl = 'http://10.0.2.2:5000';
  // in Services/api_service.dart

  Future<Map<String, dynamic>> getPreventionAdvice({
    required String crop,
    required String disease,
    String locale = 'en',
  }) async {
    final uri = Uri.parse('$baseUrl/llm/prevention');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"crop": crop, "disease": disease, "locale": locale}),
    );
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Prevention LLM failed (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<Map<String, dynamic>> getFertilizerAdvice({
    required String crop,
    required String disease,
    String locale = 'en',
  }) async {
    final uri = Uri.parse('$baseUrl/llm/fertilizer');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"crop": crop, "disease": disease, "locale": locale}),
    );
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Fertilizer LLM failed (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<double> estimateDiseaseRisk({
    required int diseaseIndex,
    required List<double> values, // must be 13 numbers in the expected order
  }) async {
    final uri = Uri.parse('$rootUrl/risk/add');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "values": values,
        "disease": diseaseIndex,
      }),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final pred = (data['prediction'] as num).toDouble();
      return pred;
    } else {
      throw Exception('Risk API failed (${resp.statusCode}): ${resp.body}');
    }
  }

  /// Crop Recommendation
  Future<Map<String, dynamic>> getCropRecommendation(
      Map<String, dynamic> formData) async {
    final uri = Uri.parse('$baseUrl/crop_recommend');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch recommendation (${resp.statusCode})');
    }
  }

  /// Plant Disease Detection
  /// Expects your Flask endpoint at /api/predict
  /// (If you use /predict-disease instead, switch the path below.)
  Future<Map<String, dynamic>> predictDisease(File imageFile) async {
    final uri = Uri.parse('$baseUrl/predict');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      return json.decode(body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Failed to get prediction (${streamed.statusCode}): $body');
    }
  }
}
