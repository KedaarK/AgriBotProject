import 'package:agribot/Services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:agribot/utils/font_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agribot/Screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController reEnterPasswordController =
      TextEditingController();
  final TextEditingController otpController =
      TextEditingController(); // ✅ OTP Input Field

  String _selectedRole = 'farmer'; // Default role
  bool isOtpSent = false; // ✅ Track if OTP is sent
  bool isOtpVerified = false; // ✅ Track if OTP is verified

  final String flaskUrl = 'http://10.0.2.2:5000';

  // 📌 Send OTP Function
  Future<void> sendOTP() async {
    var response = await http.post(
      Uri.parse("$flaskUrl/api/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": emailController.text.trim()}),
    );

    var jsonResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        isOtpSent = true; // ✅ OTP sent successfully
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(jsonResponse["message"])));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(jsonResponse["error"])));
    }
  }

  // 📌 Verify OTP Function
  Future<void> verifyOTP() async {
    var response = await http.post(
      Uri.parse("$flaskUrl/api/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text.trim(),
        "otp": otpController.text.trim(),
      }),
    );

    var jsonResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        isOtpVerified = true; // ✅ OTP Verified
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ OTP Verified! You can now register.")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(jsonResponse["error"])));
    }
  }

  void registerUser() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = reEnterPasswordController.text.trim();
    String name = nameController.text.trim();

    if (!isOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please verify your OTP before registering.")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // ✅ Call authentication service with role
    AuthService().signup(
      name: name,
      email: email,
      password: password,
      context: context,
      role: _selectedRole, // Send role to AuthService
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08), // Responsive padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.1),
              Text(
                'Register',
                style: FontHelper.getStyle(
                  textColor: const Color.fromARGB(255, 70, 116, 75),
                  fontSize: screenWidth * 0.14, // Adjust font size
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Create your own Account',
                style: FontHelper.getStyle(
                  textColor: const Color.fromARGB(255, 192, 192, 192),
                  fontSize: screenWidth * 0.06, // Adjust font size
                  fontWeight: FontWeight.w600,
                ),
              ),
              Form(
                child: Column(
                  children: [
                    _buildTextField("Name", nameController),
                    _buildTextField("Email", emailController),

                    // 📌 Send OTP Button beside Email TextField
                    if (!isOtpSent)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _customButton(
                                  "Send OTP", Colors.blue, sendOTP),
                            ),
                          ],
                        ),
                      ),

                    if (isOtpSent)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    "Enter OTP", otpController)), // ✅ OTP Field
                            const SizedBox(width: 10),
                            if (!isOtpVerified)
                              _customButton("Verify", Colors.orange, verifyOTP),

                            if (isOtpVerified)
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 30), // ✅ Tick mark
                          ],
                        ),
                      ),

                    _buildTextField("Password", passwordController,
                        isPassword: true),
                    _buildTextField(
                        "Re-Enter Password", reEnterPasswordController,
                        isPassword: true),

                    // 📊 Role Selection Dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Select Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'farmer', child: Text('Farmer')),
                          DropdownMenuItem(
                              value: 'agronomist', child: Text('Agronomist')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _customButton(
                  "Register",
                  isOtpVerified ? Colors.green : Colors.grey,
                  isOtpVerified ? registerUser : () {}),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Already Have an Account? ',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    TextSpan(
                      text: 'Sign In',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ Custom Button
  Widget _customButton(String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // 🛠️ Reusable TextField Builder
  Widget _buildTextField(String labelText, TextEditingController controller,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 219, 229, 221),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: const TextStyle(
              color: Color.fromARGB(255, 70, 116, 75),
              fontWeight: FontWeight.w500,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(18),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}
