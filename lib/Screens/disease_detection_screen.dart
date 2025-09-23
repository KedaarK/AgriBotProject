import 'dart:io';
import 'package:agribot/Screens/prediction_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribot/Services/api_service.dart';
import 'package:agribot/Screens/disease_risk_form.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  final void Function(Locale) onChangeLanguage;
  final String userEmail;
  const DiseaseDetectionScreen(
      {required this.userEmail, required this.onChangeLanguage, Key? key})
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

  // LLM state
  bool _adviceLoading = false;
  String? _adviceError;
  Map<String, dynamic>? _advice;

  bool _fertLoading = false;
  String? _fertError;
  Map<String, dynamic>? _fertAdvice;

  // Disease risk cards
  final List<String> _diseaseCards = const [
    "Leaf Blast",
    "Neck Blast",
    "Glume Discoloration",
    "Sheath Rot",
    "Sheath Blight",
    "Brown Spot",
  ];

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
        _advice = null;
        _adviceError = null;
        _fertAdvice = null;
        _fertError = null;
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

      // Save prediction to Firebase Firestore
      if (_predicted != null) {
        await _savePredictionToHistory(_predicted!, _confidence, _top5);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- LLM helpers ---

  String _extractCropFromPrediction(String full) {
    // "Tomato late blight" -> "Tomato"
    // "Potato early blight" -> "Potato"
    if (full.trim().isEmpty) return full;
    return full.split(' ').first;
  }

  Future<void> _fetchPreventiveAdvice() async {
    if (_predicted == null) return;
    final crop = _extractCropFromPrediction(_predicted!);

    setState(() {
      _adviceLoading = true;
      _adviceError = null;
      _advice = null;
    });

    try {
      final advice = await _api.getPreventionAdvice(
        crop: crop,
        disease: _predicted!,
        locale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() => _advice = advice);
      _showBottomSheet(
        title: 'Preventive measures',
        child: _AdviceView(advice: advice),
      );
    } catch (e) {
      setState(() => _adviceError = e.toString());
      _showBottomSheet(
        title: 'Preventive measures',
        isDense: true,
        child: Text('Failed to fetch advice:\n$e',
            style: TextStyle(color: Colors.red.shade700)),
      );
    } finally {
      if (mounted) setState(() => _adviceLoading = false);
    }
  }

  Future<void> _fetchFertilizerAdvice() async {
    if (_predicted == null) return;
    final crop = _extractCropFromPrediction(_predicted!);

    setState(() {
      _fertLoading = true;
      _fertError = null;
      _fertAdvice = null;
    });

    try {
      final fert = await _api.getFertilizerAdvice(
        crop: crop,
        disease: _predicted!,
        locale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() => _fertAdvice = fert);
      _showBottomSheet(
        title: 'Fertilizer guidance',
        child: _FertilizerView(data: fert),
      );
    } catch (e) {
      setState(() => _fertError = e.toString());
      _showBottomSheet(
        title: 'Fertilizer guidance',
        isDense: true,
        child: Text('Failed to fetch fertilizer advice:\n$e',
            style: TextStyle(color: Colors.red.shade700)),
      );
    } finally {
      if (mounted) setState(() => _fertLoading = false);
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

  void _showBottomSheet({
    required String title,
    required Widget child,
    bool isDense = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: isDense ? 0.4 : 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Save prediction to Firestore
  Future<void> _savePredictionToHistory(String predictedDisease,
      double? confidence, List<Map<String, dynamic>> top5) async {
    try {
      // 1. Get the current user from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;

      // 2. Check if the user is actually logged in
      if (user == null || user.email == null) {
        print("Error: User is not logged in or email is not available.");
        return; // Exit the function if no user is signed in
      }

      // 3. Use the logged-in user's email
      String userEmail = user.email!;

      // Reference to the user's document in Firestore using the dynamic email
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userEmail);

      // Create the new prediction entry
      final newPrediction = {
        'disease': predictedDisease,
        'confidence': confidence ?? 0.0,
        'timestamp': Timestamp.now(),
        'top5': top5,
      };

      // Add prediction history to the user's document
      // Using FieldValue.arrayUnion adds the new map to the array
      await userDoc.set({
        'email': userEmail, // Good practice to store the email in the doc too
        'diseasePredictions': FieldValue.arrayUnion([newPrediction])
      }, SetOptions(merge: true));

      print("Prediction saved successfully for user: $userEmail");
    } catch (e) {
      print("Error saving prediction: $e");
    }
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

              // Result card + LLM CTAs
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
                              child: _kv(l10n.predictedDisease, _predicted!)),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: (_adviceLoading)
                                  ? null
                                  : _fetchPreventiveAdvice,
                              icon: _adviceLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(
                                      Icons.volunteer_activism_rounded),
                              label: const Text('Preventive measures'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (_fertLoading)
                                  ? null
                                  : _fetchFertilizerAdvice,
                              icon: _fertLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.spa_outlined),
                              label: const Text('Fertilizer advice'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: size.width *
                        0.9, // Button takes up 80% of the screen width
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PredictionHistoryScreen(
                              userEmail: widget.userEmail,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .green[700], // Background color for the button
                        padding: EdgeInsets.symmetric(
                            vertical: size.height *
                                0.02), // Vertical padding based on screen height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              12), // Rounded corners for the button
                        ),
                      ),
                      child: Text(
                        l10n.viewPreviousPredictions, // Use localized string here
                        style: const TextStyle(
                            color: Colors.white), // White text color
                      ),
                    ),
                  ),
                ],
              ),

              // Disease Risk Estimators
              SizedBox(height: size.height * 0.03),
              Text(
                'Disease Risk Estimators',
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
                            diseaseIndex: i,
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

// ---- Renderers for LLM JSON ----

class _AdviceView extends StatelessWidget {
  final Map<String, dynamic> advice;
  const _AdviceView({required this.advice});

  Widget _bullets(List list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list
            .map<Widget>((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(e.toString())),
                    ],
                  ),
                ))
            .toList(),
      );

  @override
  Widget build(BuildContext context) {
    final s = advice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s['summary'] != null) ...[
          Text(s['summary'],
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
        ],
        if (s['cultural_practices'] != null) ...[
          const Text('Cultural practices',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _bullets(List.from(s['cultural_practices'])),
          const SizedBox(height: 12),
        ],
        if (s['sanitation_practices'] != null) ...[
          const Text('Sanitation practices',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _bullets(List.from(s['sanitation_practices'])),
          const SizedBox(height: 12),
        ],
        if (s['monitoring'] != null) ...[
          const Text('Monitoring',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _bullets(List.from(s['monitoring'])),
          const SizedBox(height: 12),
        ],
        if (s['resistant_varieties'] != null) ...[
          const Text('Resistant varieties',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _bullets(List.from(s['resistant_varieties'])),
          const SizedBox(height: 12),
        ],
        if (s['ipm'] != null) ...[
          const Text('Integrated Pest Management',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _bullets(List.from(s['ipm'])),
          const SizedBox(height: 12),
        ],
        if (s['disclaimer'] != null)
          Text(s['disclaimer'], style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _FertilizerView extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FertilizerView({required this.data});

  @override
  Widget build(BuildContext context) {
    final recs = (data['recommendations'] as List?) ?? const [];
    final schedule = (data['schedule'] as List?) ?? const [];
    final notes = data['notes']?.toString();

    Widget bullets(List l) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: l
              .map<Widget>((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(e.toString())),
                      ],
                    ),
                  ))
              .toList(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recs.isNotEmpty) ...[
          const Text('Recommendations',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          bullets(recs),
          const SizedBox(height: 12),
        ],
        if (schedule.isNotEmpty) ...[
          const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          bullets(schedule),
          const SizedBox(height: 12),
        ],
        if (notes != null && notes.isNotEmpty)
          Text(notes, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
