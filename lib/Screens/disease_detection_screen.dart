import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:agribot/Services/api_service.dart';
import 'package:agribot/Screens/disease_risk_form.dart'; // <-- NEW: form screen import

class DiseaseDetectionScreen extends StatefulWidget {
  final void Function(Locale) onChangeLanguage;
  const DiseaseDetectionScreen({required this.onChangeLanguage, Key? key})
      : super(key: key);

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  final _picker = ImagePicker();
  final _api = ApiService();

  File? _image;
  bool _loading = false;
  String? _predicted;
  double? _confidence;
  List<Map<String, dynamic>> _top5 = [];
  String? _error;

  // ---------------- NEW: disease cards list ----------------
  final List<String> _diseaseCards = const [
    "Leaf Blast",
    "Neck Blast",
    "Glume Discoloration",
    "Sheath Rot",
    "Sheath Blight",
    "Brown Spot",
  ];
  // ---------------------------------------------------------

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;
      setState(() {
        _image = File(picked.path);
        _predicted = null;
        _confidence = null;
        _top5.clear();
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _predicted = null;
      _confidence = null;
      _top5.clear();
    });

    try {
      final resp = await _api.predictDisease(_image!);
      final disease =
          (resp['predicted_disease'] ?? resp['prediction'])?.toString();
      final conf = (resp['confidence'] as num?)?.toDouble();

      final top = (resp['top5'] as List?)
              ?.map((e) => {
                    'label': e['label']?.toString() ?? '',
                    'confidence': (e['confidence'] as num?)?.toDouble() ?? 0.0
                  })
              .toList() ??
          [];

      setState(() {
        _predicted = disease;
        _confidence = conf;
        _top5 = top.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                widget.onChangeLanguage(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('हिन्दी'),
              onTap: () {
                widget.onChangeLanguage(const Locale('hi'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('मराठी'),
              onTap: () {
                widget.onChangeLanguage(const Locale('mr'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final pad = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diseaseDetectionTitle),
        actions: [
          IconButton(
            tooltip: l10n.selectLanguage,
            icon: const Icon(Icons.language),
            onPressed: _showLanguageDialog,
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: pad, vertical: size.height * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                l10n.uploadOrCaptureLeaf,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: size.height * 0.02),

              // Image preview
              Container(
                height: size.height * 0.32,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: _image == null
                    ? Center(
                        child: Text(
                          l10n.noImageSelected,
                          style: TextStyle(
                              fontSize: size.width * 0.04,
                              color: Colors.grey[700]),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!,
                            fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
              SizedBox(height: size.height * 0.02),

              // Buttons (camera / gallery)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(l10n.takePicture),
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: size.height * 0.016),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: Text(l10n.chooseFromGallery),
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: size.height * 0.016),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.02),

              // Analyze button
              ElevatedButton(
                onPressed: (_image != null && !_loading) ? _analyze : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.analyzeButton,
                    style: const TextStyle(color: Colors.white)),
              ),

              if (_loading) ...[
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Processing...'),
                  ],
                ),
              ],

              // Error
              if (_error != null && !_loading) ...[
                SizedBox(height: size.height * 0.02),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    l10n.predictionFailed(_error!),
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
              ],

              // Result card
              if (_predicted != null && !_loading) ...[
                SizedBox(height: size.height * 0.02),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.08),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Result',
                          style: TextStyle(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.w700,
                            color: Colors.green[900],
                          )),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _kv(l10n.predictedDisease, _predicted!),
                          ),
                          if (_confidence != null)
                            Expanded(
                              child: _kv(
                                l10n.confidenceLabel,
                                '${_confidence!.toStringAsFixed(2)}%',
                              ),
                            ),
                        ],
                      ),
                      if (_top5.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.topPredictions,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._top5.map((e) {
                          final label = e['label']?.toString() ?? '';
                          final conf =
                              (e['confidence'] as num?)?.toDouble() ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(label)),
                                SizedBox(
                                  width: 120,
                                  child: LinearProgressIndicator(
                                    value: (conf / 100.0).clamp(0.0, 1.0),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${conf.toStringAsFixed(1)}%'),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ],

              // ---------------- NEW: Disease Risk Estimators section ----------------
              SizedBox(height: size.height * 0.03),
              Text(
                'Disease Risk Estimators', // add to ARB later if you like
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[900],
                ),
              ),
              const SizedBox(height: 10),

              GridView.builder(
                itemCount: _diseaseCards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, i) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiseaseRiskForm(
                            diseaseName: _diseaseCards[i],
                            diseaseIndex:
                                i, // maps directly to backend “disease”
                          ),
                        ),
                      );
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_hospital,
                                color: Colors.green[700], size: 28),
                            const SizedBox(height: 12),
                            Text(
                              _diseaseCards[i],
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to enter parameters',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // --------------------------------------------------------------------
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(v),
      ],
    );
  }
}
