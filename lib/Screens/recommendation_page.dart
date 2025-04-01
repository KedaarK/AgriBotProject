import 'package:flutter/material.dart';
import 'package:agribot/Services/api_service.dart';

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
  final ApiService _apiService = ApiService();

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
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Recommendation'),
        backgroundColor: Colors.green[900],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: size.height * 0.02, horizontal: padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter Soil & Weather Parameters',
                  style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.02),
                _buildTextField(_nController, 'Nitrogen (N)', false, size),
                _buildTextField(_pController, 'Phosphorus (P)', false, size),
                _buildTextField(_kController, 'Potassium (K)', false, size),
                _buildTextField(
                    _temperatureController, 'Temperature (°C)', true, size),
                _buildTextField(
                    _humidityController, 'Humidity (%)', true, size),
                _buildTextField(_phController, 'pH Level', true, size),
                _buildTextField(
                    _rainfallController, 'Rainfall (mm)', true, size),
                SizedBox(height: size.height * 0.02),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getRecommendation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.black)
                      : Text('Get Recommendation',
                          style: TextStyle(fontSize: size.width * 0.045)),
                ),
                SizedBox(height: size.height * 0.02),
                if (_recommendedCrop.isNotEmpty)
                  Card(
                    color: Colors.green.shade50,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(size.width * 0.04),
                      child: Column(
                        children: [
                          Text(
                            'Recommended Crop:',
                            style: TextStyle(
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: size.height * 0.01),
                          Text(
                            _recommendedCrop,
                            style: TextStyle(
                                fontSize: size.width * 0.055,
                                color: Colors.green[700]),
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

  Widget _buildTextField(TextEditingController controller, String label,
      bool isDouble, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
      child: TextFormField(
        controller: controller,
        keyboardType:
            TextInputType.numberWithOptions(decimal: isDouble, signed: false),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
              vertical: size.height * 0.02, horizontal: size.width * 0.04),
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
