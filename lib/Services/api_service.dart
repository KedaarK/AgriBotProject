import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Point this at your Flask base (note the /api suffix based on your routes)
  // For Android emulator -> host machine, you can use: http://10.0.2.2:5000/api
  // final String baseUrl = 'http://10.210.119.19:5000/api';
  // final String rootUrl = 'http://10.210.119.119:5000';
  static final ApiService instance = ApiService();
  final String baseUrl = 'http://10.0.2.2:5000/api';
  final String rootUrl = 'http://10.0.2.2:5000';

  // ---------- Helpers ----------
  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late http.Response resp;
    try {
      resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timed out');
    }

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected payload: ${resp.body}');
    }
    return decoded;
  }

  // ---------- CHAT ----------
  /// Non-streaming chat: POST /api/chat  -> {"reply": "..."}
  Future<String> sendMessage(String userText, {String locale = 'en'}) async {
    final uri = Uri.parse('$baseUrl/chat');
    final resp = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'message': userText, 'locale': locale}), // include locale
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final jsonMap = jsonDecode(resp.body);
    final reply = jsonMap['reply']?.toString();
    if (reply == null) {
      throw Exception('Malformed chat response: ${resp.body}');
    }
    return reply;
  }

  /// Streaming chat (SSE): POST /api/chat/stream -> text/event-stream
  /// Yields chunks (strings). Stop when you receive "[DONE]".
  Stream<String> streamMessage(String userText, {String locale = 'en'}) async* {
    final uri = Uri.parse('$baseUrl/chat/stream');
    final req = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({'message': userText, 'locale': locale});

    http.StreamedResponse resp;
    try {
      resp = await req.send().timeout(const Duration(seconds: 60));
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Stream request timed out');
    }

    if (resp.statusCode != 200) {
      final err = await resp.stream.bytesToString();
      throw Exception('HTTP ${resp.statusCode}: $err');
    }

    // Parse SSE lines: each event is "data: <chunk>\n\n"
    final stream = resp.stream
        .transform(const Utf8Decoder())
        .transform(const LineSplitter());
    await for (final line in stream) {
      if (!line.startsWith('data:')) continue;
      final chunk = line.substring(5).trim();
      yield chunk;
      if (chunk == '[DONE]') break;
    }
  }

  // ---------- LLM JSON: Prevention (kept) ----------
  Future<Map<String, dynamic>> getPreventionAdvice({
    required String crop,
    required String disease,
    String locale = 'en',
  }) async {
    return _postJson('/llm/prevention', {
      'crop': crop,
      'disease': disease,
      'locale': locale,
    });
  }

  // ---------- LLM JSON: Fertilizer (kept) ----------
  Future<Map<String, dynamic>> getFertilizerAdvice({
    required String crop,
    required String disease,
    String locale = 'en',
  }) async {
    return _postJson('/llm/fertilizer', {
      'crop': crop,
      'disease': disease,
      'locale': locale,
    });
  }

  // ---------- LLM JSON: NEW endpoints you added in Flask ----------

  /// Treatment / Solution
  Future<Map<String, dynamic>> getSolutionAdvice({
    required String crop,
    required String disease,
    String locale = 'en',
  }) async {
    return _postJson('/llm/solution', {
      'crop': crop,
      'disease': disease,
      'locale': locale,
    });
  }

  /// Waste / Residue Management
  Future<Map<String, dynamic>> getWasteManagement({
    required String crop,
    String locale = 'en',
  }) async {
    return _postJson('/llm/waste_management', {
      'crop': crop,
      'locale': locale,
    });
  }

  /// Soil Suitability
  Future<Map<String, dynamic>> getSoilSuitability({
    required String crop,
    required String soilType,
    String locale = 'en',
  }) async {
    return _postJson('/llm/soil_suitability', {
      'crop': crop,
      'soil_type': soilType,
      'locale': locale,
    });
  }

  /// Market Quote (does math and returns a breakdown)
  Future<Map<String, dynamic>> getMarketQuote({
    required String crop,
    required String marketName,
    required String marketCity,
    required double unitPrice,
    required double quantity,
    required String unit,
    required double transportKm,
    required double transportRatePerKm,
    String locale = 'en',
  }) async {
    return _postJson('/llm/market_quote', {
      'crop': crop,
      'market_name': marketName,
      'market_city': marketCity,
      'unit_price': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'transport_km': transportKm,
      'transport_rate_per_km': transportRatePerKm,
      'locale': locale,
    });
  }

  // in Services/api_service.dart

  Future<List<Map<String, dynamic>>> estimateDiseaseRisk({
    required List<double> values, // Must be 13 numbers in the expected order
  }) async {
    final uri = Uri.parse('$rootUrl/risk/add');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "values": values,
      }),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;

      // Changed from 'predictions' to 'diseases' to match your JSON
      final diseases = (data['diseases'] as List)
          .map((disease) => {
                'disease': disease['disease'],
                'prediction': (disease['value'] as num)
                    .toDouble() // Changed from 'prediction' to 'value'
              })
          .toList();
      return diseases;
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
