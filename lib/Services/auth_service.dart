import 'package:agribot/Screens/bottom_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:agribot/Screens/Agronomist/agronomist_dashboard.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SIGN UP FUNCTION WITH ROLE
  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
    required String name,
    required String role, // "farmer" or "agronomist"
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user details and role in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "name": name,
        "email": email,
        "role": role,
      });

      Fluttertoast.showToast(
        msg: "Signup Successful!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      _redirectBasedOnRole(role, context);
    } on FirebaseAuthException catch (e) {
      _showErrorToast(e.code);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An unexpected error occurred.",
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    }
  }

  // SIGN IN FUNCTION WITH ROLE CHECK
  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Sign in user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user role from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        Fluttertoast.showToast(
          msg: "User not found in database.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null || !userData.containsKey('role')) {
        Fluttertoast.showToast(
          msg: "User role not found.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      String role = userData['role'];
      print('$role');
      _redirectBasedOnRole(role, context);
    } on FirebaseAuthException catch (e) {
      _showErrorToast(e.code);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An unexpected error occurred: ${e.toString()}",
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    }
  }

  // REDIRECT BASED ON ROLE
  void _redirectBasedOnRole(String role, BuildContext context) async {
    print("Redirecting to: $role");

    await Future.delayed(const Duration(milliseconds: 300)); // Short delay

    if (!context.mounted) return; // ✅ Check if context is valid

    Widget targetScreen;
    if (role == "farmer") {
      targetScreen = BottomNavigation();
    } else if (role == "agronomist") {
      targetScreen = AgronomistDashboard();
    } else {
      Fluttertoast.showToast(
        msg: "Invalid user role.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 1000), // Smooth duration
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // ERROR HANDLING
  void _showErrorToast(String code) {
    String message = '';
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

    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}
