import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // For Localizations

class PredictionHistoryScreen extends StatefulWidget {
  // 1. Add a final variable to hold the email
  final String userEmail;

  // 2. Add it as a required parameter in the constructor
  const PredictionHistoryScreen({
    Key? key,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<PredictionHistoryScreen> createState() =>
      _PredictionHistoryScreenState();
}

class _PredictionHistoryScreenState extends State<PredictionHistoryScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _history = [];
  bool _isInit = true;
  // Fetch previous predictions from Firestore
  Future<void> _fetchPredictionHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. REMOVE all the Firebase Auth code.
      // 2. USE the email passed from the previous screen via `widget`.
      String userEmail = widget.userEmail;

      // The rest of your function stays exactly the same!
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (userDoc.exists) {
        List predictions = userDoc.get('diseasePredictions') ?? [];
        setState(() {
          _history = predictions.map((e) {
            return {
              'disease': e['disease']?.toString(),
              'confidence': e['confidence']?.toString(),
              'timestamp': (e['timestamp'] as Timestamp?)?.toDate(),
              'top5': e['top5'],
            };
          }).toList();
        });
      } else {
        setState(() {
          _error = AppLocalizations.of(context)!.noPredictionsFound;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Save prediction to Firestore
  Future<void> _savePredictionToHistory(String predictedDisease,
      double? confidence, List<Map<String, dynamic>> top5) async {
    try {
      // Get the currently authenticated user's email from FirebaseAuth
      String? userEmail = FirebaseAuth.instance.currentUser?.email;

      if (userEmail == null) {
        print("User is not logged in!");
        return;
      }

      // Reference to the user's document in Firestore
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userEmail);

      // Add prediction history to the user's document
      await userDoc.set({
        'email': userEmail,
        'diseasePredictions': FieldValue.arrayUnion([
          {
            'disease': predictedDisease,
            'confidence': confidence ?? 0.0,
            'timestamp': Timestamp.now(),
            'top5': top5,
          }
        ])
      }, SetOptions(merge: true));

      print("Prediction saved successfully!");
    } catch (e) {
      print("Error saving prediction: $e");
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // 3. Move the logic here. It's safe to use context in this method.
    if (_isInit) {
      _fetchPredictionHistory();
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Fetch localized strings

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.predictionHistoryTitle), // Use localized string
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(l10n
                        .errorMessage(_error!))) // Use localized error message
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      var prediction = _history[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(prediction['disease']),
                          subtitle: Text(
                              '${l10n.confidenceLabel}: ${prediction['confidence']}%\n${l10n.dateLabel}: ${prediction['timestamp']}'),
                          onTap: () {
                            // Show more detailed prediction info if necessary
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
