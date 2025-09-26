import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agribot/Services/api_service.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({Key? key}) : super(key: key);

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  // Controllers (keep order consistent with backend!)
  final _n = TextEditingController();
  final _p = TextEditingController();
  final _k = TextEditingController();
  final _temperature = TextEditingController();
  final _humidity = TextEditingController();
  final _ph = TextEditingController();
  final _rainfall = TextEditingController();

  bool _loading = false;
  String? _recommendedCrop;
  String? _error;

  final _focus = List<FocusNode>.generate(7, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in [_n, _p, _k, _temperature, _humidity, _ph, _rainfall]) {
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
      _recommendedCrop = null;
      _error = null;
    });

    try {
      final formData = {
        'N': int.parse(_n.text.trim()),
        'P': int.parse(_p.text.trim()),
        'K': int.parse(_k.text.trim()),
        'temperature': double.parse(_temperature.text.trim()),
        'humidity': double.parse(_humidity.text.trim()),
        'ph': double.parse(_ph.text.trim()),
        'rainfall': double.parse(_rainfall.text.trim()),
      };

      final response = await _api.getCropRecommendation(formData);

      if (!mounted) return;
      setState(() => _recommendedCrop =
          response['recommended_crop'] ?? 'No recommendation found');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearAll() {
    for (final c in [_n, _p, _k, _temperature, _humidity, _ph, _rainfall]) {
      c.clear();
    }
    setState(() {
      _recommendedCrop = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final pad = sz.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Recommendation"),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            onPressed: _loading ? null : _clearAll,
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
              _headerCard("Soil & Weather Parameters"),
              const SizedBox(height: 16),
              _sectionTitle('Soil Nutrients'),
              _numField(
                controller: _n,
                focusNode: _focus[0],
                label: 'Nitrogen (N)',
                hint: 'ppm',
                icon: Icons.park_outlined,
                onFieldSubmitted: (_) => _focus[1].requestFocus(),
              ),
              _numField(
                controller: _p,
                focusNode: _focus[1],
                label: 'Phosphorus (P)',
                hint: 'ppm',
                icon: Icons.grass_outlined,
                onFieldSubmitted: (_) => _focus[2].requestFocus(),
              ),
              _numField(
                controller: _k,
                focusNode: _focus[2],
                label: 'Potassium (K)',
                hint: 'ppm',
                icon: Icons.eco_outlined,
                onFieldSubmitted: (_) => _focus[3].requestFocus(),
              ),
              const SizedBox(height: 16),
              _sectionTitle('Weather'),
              _numField(
                controller: _temperature,
                focusNode: _focus[3],
                label: 'Temperature',
                hint: '°C',
                suffixText: '°C',
                icon: Icons.thermostat_outlined,
                onFieldSubmitted: (_) => _focus[4].requestFocus(),
              ),
              _numField(
                controller: _humidity,
                focusNode: _focus[4],
                label: 'Humidity',
                hint: '%',
                suffixText: '%',
                icon: Icons.water_drop_outlined,
                onFieldSubmitted: (_) => _focus[5].requestFocus(),
              ),
              _numField(
                controller: _ph,
                focusNode: _focus[5],
                label: 'Soil pH',
                hint: '0–14',
                icon: Icons.science_outlined,
                onFieldSubmitted: (_) => _focus[6].requestFocus(),
              ),
              _numField(
                controller: _rainfall,
                focusNode: _focus[6],
                label: 'Rainfall',
                hint: 'mm',
                suffixText: 'mm',
                icon: Icons.cloud_outlined,
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
              if (_recommendedCrop != null)
                _infoCard(
                  title: 'Recommended Crop',
                  color: Colors.green.shade50,
                  borderColor: Colors.green.shade200,
                  child: Text(
                    _recommendedCrop!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      // Sticky bottom bar
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
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
            label: Text(
              _loading ? 'Sending...' : 'Get Recommendation',
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
          Icon(Icons.agriculture_outlined, color: Colors.green.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
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
