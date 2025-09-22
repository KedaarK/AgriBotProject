import 'package:agribot/Screens/bottom_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agribot/Screens/Agronomist/agronomist_dashboard.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showToast(BuildContext context, String message,
      {bool isError = false}) {
    // If your Flutter version doesn’t support context.mounted, remove this line.
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.7,
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // SIGN UP FUNCTION WITH ROLE
  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
    required String name,
    required String role, // "farmer" or "agronomist"
    required void Function(Locale) onChangeLanguage, // <-- add this
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "name": name,
        "email": email,
        "role": role,
      });

      _showToast(context, "Signup Successful!");

      _redirectBasedOnRole(role, context, onChangeLanguage); // <-- pass it
    } on FirebaseAuthException catch (e) {
      _showErrorMessage(context, e.code);
    } catch (e) {
      _showToast(context, "An unexpected error occurred.", isError: true);
    }
  }

  // SIGN IN FUNCTION WITH ROLE CHECK
  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
    required void Function(Locale) onChangeLanguage, // <-- add this
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        _showToast(context, "User not found in database.", isError: true);
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null || !userData.containsKey('role')) {
        _showToast(context, "User role not found.", isError: true);
        return;
      }

      final String role = userData['role'] as String;
      _redirectBasedOnRole(role, context, onChangeLanguage); // <-- pass it
    } on FirebaseAuthException catch (e) {
      _showErrorMessage(context, e.code);
    } catch (e) {
      _showToast(context, "An unexpected error occurred: ${e.toString()}",
          isError: true);
    }
  }

  // REDIRECT BASED ON ROLE
  void _redirectBasedOnRole(
    String role,
    BuildContext context,
    void Function(Locale) onChangeLanguage, // <-- accept it
  ) {
    // Optional tiny delay
    // await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return;

    late final Widget targetScreen;
    if (role == "farmer") {
      targetScreen =
          BottomNavigation(onChangeLanguage: onChangeLanguage); // <-- use it
    } else if (role == "agronomist") {
      targetScreen =
          const AgronomistDashboard(); // add language button later if needed
    } else {
      _showToast(context, "Invalid user role.", isError: true);
      return;
    }

    // Clear stack so back from Home doesn't go to Login/Register
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, __) =>
            FadeTransition(opacity: animation, child: targetScreen),
      ),
      (route) => false,
    );
  }

  void _showErrorMessage(BuildContext context, String code) {
    String message;
    switch (code) {
      case 'invalid-email':
        message = 'The email address is badly formatted.';
        break;
      case 'user-disabled':
        message = 'This user has been disabled.';
        break;
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password provided.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      default:
        message = 'An unexpected error occurred.';
    }
    _showToast(context, message, isError: true);
  }
}
