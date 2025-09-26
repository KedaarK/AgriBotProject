import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agribot/Services/api_service.dart';

class DiseaseRiskForm extends StatefulWidget {
  const DiseaseRiskForm({Key? key}) : super(key: key);

  @override
  State<DiseaseRiskForm> createState() => _DiseaseRiskFormState();
}

class _DiseaseRiskFormState extends State<DiseaseRiskForm> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  // Disease mapping - matches your backend model indices
  final Map<int, String> _diseaseNames = {
    0: 'Leaf Blast',
    1: 'Neck Blast',
    2: 'Glume Discoloration',
    3: 'Sheath Rot',
    4: 'Sheath Blight',
    5: 'Brown Spot',
  };

  // Controllers (keep order consistent with backend!)
  final _stage = TextEditingController();
  final _maxTemp = TextEditingController();
  final _minTemp = TextEditingController();
  final _relH1 = TextEditingController();
  final _relH2 = TextEditingController();
  final _rainfall = TextEditingController();
  final _rainyDays = TextEditingController();
  final _sunHours = TextEditingController();
  final _windSpeed = TextEditingController();
  final _soilPh = TextEditingController();
  final _nitrogen = TextEditingController();
  final _potassium = TextEditingController();
  final _salinity = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>>? _predictions;
  String? _error;

  final _focus = List<FocusNode>.generate(13, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in [
      _stage,
      _maxTemp,
      _minTemp,
      _relH1,
      _relH2,
      _rainfall,
      _rainyDays,
      _sunHours,
      _windSpeed,
      _soilPh,
      _nitrogen,
      _potassium,
      _salinity,
    ]) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  String? _numValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return double.tryParse(v.trim()) == null ? 'Enter a valid number' : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _predictions = null;
      _error = null;
    });

    try {
      final vals = <double>[
        double.parse(_stage.text.trim()),
        double.parse(_maxTemp.text.trim()),
        double.parse(_minTemp.text.trim()),
        double.parse(_relH1.text.trim()),
        double.parse(_relH2.text.trim()),
        double.parse(_rainfall.text.trim()),
        double.parse(_rainyDays.text.trim()),
        double.parse(_sunHours.text.trim()),
        double.parse(_windSpeed.text.trim()),
        double.parse(_soilPh.text.trim()),
        double.parse(_nitrogen.text.trim()),
        double.parse(_potassium.text.trim()),
        double.parse(_salinity.text.trim()),
      ];

      // Make the API call - this now returns List<Map<String, dynamic>>
      final response = await _api.estimateDiseaseRisk(values: vals);

      // Directly assign the response since it's already a List<Map<String, dynamic>>
      setState(() {
        _predictions = response;
      });
    } catch (e) {
      print('Error in disease risk prediction: $e');
      setState(() {
        if (e.toString().contains('SocketException')) {
          _error =
              'Network error: Please check your internet connection and ensure the server is running';
        } else if (e.toString().contains('TimeoutException')) {
          _error = 'Request timeout: The server is taking too long to respond';
        } else if (e.toString().contains('FormatException')) {
          _error = 'Invalid response format from server';
        } else {
          _error = 'Error: ${e.toString()}';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearAll() {
    for (final c in [
      _stage,
      _maxTemp,
      _minTemp,
      _relH1,
      _relH2,
      _rainfall,
      _rainyDays,
      _sunHours,
      _windSpeed,
      _soilPh,
      _nitrogen,
      _potassium,
      _salinity,
    ]) {
      c.clear();
    }
    setState(() {
      _predictions = null;
      _error = null;
    });
  }

  // Helper method to get disease name from index
  String _getDiseaseName(int diseaseIndex) {
    return _diseaseNames[diseaseIndex] ?? 'Unknown Disease ($diseaseIndex)';
  }

  // Helper method to format prediction value
  String _formatPrediction(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value >= 100) {
      return value.toStringAsFixed(0);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final pad = sz.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Risk Estimator'),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            onPressed: _loading
                ? null
                : _clearAll, // Fixed: now calls _clearAll instead of dispose
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 100),
            children: [
              _headerCard('Enter Disease Parameters'),
              const SizedBox(height: 16),
              _sectionTitle('Crop & Soil'),
              _numField(
                controller: _stage,
                focusNode: _focus[0],
                label: 'Stage',
                hint: 'e.g., 1–10',
                icon: Icons.category_outlined,
                onFieldSubmitted: (_) => _focus[1].requestFocus(),
              ),
              _numField(
                controller: _soilPh,
                focusNode: _focus[9],
                label: 'Soil pH',
                hint: 'e.g., 6.5',
                icon: Icons.science_outlined,
                onFieldSubmitted: (_) => _focus[10].requestFocus(),
              ),
              _numField(
                controller: _nitrogen,
                focusNode: _focus[10],
                label: 'Nitrogen',
                hint: 'ppm',
                icon: Icons.park_outlined,
                onFieldSubmitted: (_) => _focus[11].requestFocus(),
              ),
              _numField(
                controller: _potassium,
                focusNode: _focus[11],
                label: 'Potassium',
                hint: 'ppm',
                icon: Icons.grass_outlined,
                onFieldSubmitted: (_) => _focus[12].requestFocus(),
              ),
              _numField(
                controller: _salinity,
                focusNode: _focus[12],
                label: 'Salinity',
                hint: 'dS/m',
                icon: Icons.water_damage_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _sectionTitle('Weather'),
              _numField(
                controller: _maxTemp,
                focusNode: _focus[1],
                label: 'Max Temperature',
                hint: '°C',
                suffixText: '°C',
                icon: Icons.thermostat_auto_outlined,
                onFieldSubmitted: (_) => _focus[2].requestFocus(),
              ),
              _numField(
                controller: _minTemp,
                focusNode: _focus[2],
                label: 'Min Temperature',
                hint: '°C',
                suffixText: '°C',
                icon: Icons.ac_unit_outlined,
                onFieldSubmitted: (_) => _focus[3].requestFocus(),
              ),
              _numField(
                controller: _relH1,
                focusNode: _focus[3],
                label: 'Relative Humidity 1',
                hint: '%',
                suffixText: '%',
                icon: Icons.percent_outlined,
                onFieldSubmitted: (_) => _focus[4].requestFocus(),
              ),
              _numField(
                controller: _relH2,
                focusNode: _focus[4],
                label: 'Relative Humidity 2',
                hint: '%',
                suffixText: '%',
                icon: Icons.percent_outlined,
                onFieldSubmitted: (_) => _focus[5].requestFocus(),
              ),
              _numField(
                controller: _rainfall,
                focusNode: _focus[5],
                label: 'Rainfall',
                hint: 'mm',
                suffixText: 'mm',
                icon: Icons.beach_access_outlined,
                onFieldSubmitted: (_) => _focus[6].requestFocus(),
              ),
              _numField(
                controller: _rainyDays,
                focusNode: _focus[6],
                label: 'Rainy Days',
                hint: 'days',
                suffixText: 'days',
                icon: Icons.calendar_month_outlined,
                onFieldSubmitted: (_) => _focus[7].requestFocus(),
              ),
              _numField(
                controller: _sunHours,
                focusNode: _focus[7],
                label: 'Sunshine Hours',
                hint: 'hrs',
                suffixText: 'hrs',
                icon: Icons.wb_sunny_outlined,
                onFieldSubmitted: (_) => _focus[8].requestFocus(),
              ),
              _numField(
                controller: _windSpeed,
                focusNode: _focus[8],
                label: 'Wind Speed',
                hint: 'km/h',
                suffixText: 'km/h',
                icon: Icons.air_outlined,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                _infoCard(
                  title: 'Error',
                  color: Colors.red.shade50,
                  borderColor: Colors.red.shade200,
                  child: Text(_error!,
                      style: TextStyle(color: Colors.red.shade800)),
                ),
              if (_predictions != null)
                _infoCard(
                  title: 'Disease Risk Predictions',
                  color: Colors.green.shade50,
                  borderColor: Colors.green.shade200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _predictions!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pred = entry.value;
                      final diseaseIndex = pred['disease'] as int;
                      final riskValue = pred['prediction'] as double;
                      final diseaseName = _getDiseaseName(diseaseIndex);
                      final formattedValue = _formatPrediction(riskValue);

                      // Color coding based on rank
                      Color textColor = Colors.green.shade800;
                      String rankText = '';
                      if (index == 0) {
                        textColor = Colors.red.shade700;
                        rankText = '🔴 HIGHEST RISK';
                      } else if (index == 1) {
                        textColor = Colors.orange.shade700;
                        rankText = '🟡 MEDIUM RISK';
                      } else {
                        textColor = Colors.green.shade700;
                        rankText = '🟢 LOW RISK';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: textColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diseaseName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Risk Score: $formattedValue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                                Text(
                                  rankText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),

      // Sticky bottom bar for primary action
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, color: Colors.white),
            label: Text(
              _loading ? 'Analyzing...' : 'Analyze Disease Risk',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI helpers ---

  Widget _headerCard(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.local_hospital_outlined, color: Colors.green.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Disease Risk Input — $title',
              style: TextStyle(
                color: Colors.green.shade900,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: Colors.green.shade900,
        ),
      ),
    );
  }

  Widget _numField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    String? hint,
    String? suffixText,
    IconData? icon,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: _numValidator,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*[.]?[0-9]*$')),
        ],
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixText: suffixText,
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required Color color,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }
}
