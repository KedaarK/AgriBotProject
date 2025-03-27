import 'package:flutter/material.dart';
import 'package:agribot/Services/api_service.dart'; // Import ApiService

class RecommendationPage extends StatefulWidget {
  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nController = TextEditingController();
  final _pController = TextEditingController();
  final _kController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _phController = TextEditingController();
  final _rainfallController = TextEditingController();

  String _recommendedCrop = '';
  bool _isLoading = false;
  final ApiService _apiService =
      ApiService(); //  Create an instance of ApiService

  Future<void> _getRecommendation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _recommendedCrop = '';
      });

      try {
        Map<String, dynamic> formData = {
          'N': int.parse(_nController.text),
          'P': int.parse(_pController.text),
          'K': int.parse(_kController.text),
          'temperature': double.parse(_temperatureController.text),
          'humidity': double.parse(_humidityController.text),
          'ph': double.parse(_phController.text),
          'rainfall': double.parse(_rainfallController.text),
        };

        Map<String, dynamic> response =
            await _apiService.getCropRecommendation(formData);

        setState(() {
          _recommendedCrop =
              response['recommended_crop'] ?? 'No recommendation found';
        });
      } catch (e) {
        setState(() {
          _recommendedCrop = 'Error: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _phController.dispose();
    _rainfallController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Recommendation'),
        backgroundColor: Colors.green[900],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter Soil & Weather Parameters',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                _buildTextField(_nController, 'Nitrogen (N)', false),
                _buildTextField(_pController, 'Phosphorus (P)', false),
                _buildTextField(_kController, 'Potassium (K)', false),
                _buildTextField(
                    _temperatureController, 'Temperature (°C)', true),
                _buildTextField(_humidityController, 'Humidity (%)', true),
                _buildTextField(_phController, 'pH Level', true),
                _buildTextField(_rainfallController, 'Rainfall (mm)', true),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getRecommendation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.black)
                      : Text('Get Recommendation',
                          style: TextStyle(fontSize: 18)),
                ),
                SizedBox(height: 20),
                if (_recommendedCrop.isNotEmpty)
                  Card(
                    color: Colors.green.shade50,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Recommended Crop:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            _recommendedCrop,
                            style: TextStyle(
                                fontSize: 22, color: Colors.green[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool isDouble) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType:
            TextInputType.numberWithOptions(decimal: isDouble, signed: false),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          return isDouble
              ? double.tryParse(value) == null
                  ? 'Enter a valid number'
                  : null
              : int.tryParse(value) == null
                  ? 'Enter a valid number'
                  : null;
        },
      ),
    );
  }
}
