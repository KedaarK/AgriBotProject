import 'package:agribot/Services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:agribot/utils/font_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agribot/Screens/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  final void Function(Locale) onChangeLanguage; // <-- add this
  const RegisterScreen({required this.onChangeLanguage, super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController reEnterPasswordController =
      TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String _selectedRole = 'farmer';
  bool isOtpSent = false;
  bool isOtpVerified = false;

  final String flaskUrl = 'http://10.0.2.2:5000';

  Future<void> sendOTP() async {
    final l10n = AppLocalizations.of(context)!;
    var response = await http.post(
      Uri.parse("$flaskUrl/api/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": emailController.text.trim()}),
    );

    var jsonResponse = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() => isOtpSent = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(jsonResponse["message"])));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse["error"] ?? l10n.genericError)));
    }
  }

  Future<void> verifyOTP() async {
    final l10n = AppLocalizations.of(context)!;
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
      setState(() => isOtpVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpVerified)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse["error"] ?? l10n.genericError)));
    }
  }

  void registerUser() {
    final l10n = AppLocalizations.of(context)!;

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = reEnterPasswordController.text.trim();
    String name = nameController.text.trim();

    if (!isOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verifyOtpFirst)),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordsDoNotMatch)),
      );
      return;
    }

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields)),
      );
      return;
    }

    AuthService().signup(
      name: name,
      email: email,
      password: password,
      context: context,
      role: _selectedRole,
      onChangeLanguage: widget.onChangeLanguage,
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Your original content
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.1),
                  Text(
                    l10n.registerTitle, // "Register"
                    key: const Key('TitleRegister'),
                    style: FontHelper.getStyle(
                      textColor: const Color.fromARGB(255, 70, 116, 75),
                      fontSize: screenWidth * 0.14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.registerSubtitle, // "Create your own Account"
                    key: const Key('SubtitleCreateAccount'),
                    style: FontHelper.getStyle(
                      textColor: const Color.fromARGB(255, 192, 192, 192),
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Form(
                    child: Column(
                      children: [
                        _buildTextField(l10n.nameLabel, nameController,
                            key: const Key('NameField')),
                        _buildTextField(l10n.emailLabel, emailController,
                            key: const Key('EmailField')),
                        if (!isOtpSent)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    key: const Key('SendOtpButton'),
                                    onTap: sendOTP,
                                    child: _customButton(
                                        l10n.sendOtp, Colors.blue, () {}),
                                  ),
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
                                      l10n.enterOtpLabel, otpController,
                                      key: const Key('OtpField')),
                                ),
                                const SizedBox(width: 10),
                                if (!isOtpVerified)
                                  _customButton(
                                      l10n.verifyOtp, Colors.orange, verifyOTP,
                                      key: const Key('VerifyOtpButton')),
                                if (isOtpVerified)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 30),
                              ],
                            ),
                          ),
                        _buildTextField(l10n.passwordLabel, passwordController,
                            isPassword: true, key: const Key('PasswordField')),
                        _buildTextField(l10n.reEnterPasswordLabel,
                            reEnterPasswordController,
                            isPassword: true,
                            key: const Key('ConfirmPasswordField')),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: DropdownButtonFormField<String>(
                            key: const Key('RoleDropdown'),
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: l10n.selectRole,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            items: [
                              DropdownMenuItem(
                                  value: 'farmer',
                                  child: Text(l10n.roleFarmer)),
                              DropdownMenuItem(
                                  value: 'agronomist',
                                  child: Text(l10n.roleAgronomist)),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedRole = value!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _customButton(
                    l10n.registerCta, // "Register"
                    isOtpVerified ? Colors.green : Colors.grey,
                    isOtpVerified ? registerUser : () {},
                    key: const Key('RegisterSubmitButton'),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    key: const Key('GoToSignInLink'),
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.alreadyHaveAccount + ' ',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        TextSpan(
                          text: l10n.signIn,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(
                                    onChangeLanguage: widget.onChangeLanguage,
                                  ),
                                ),
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

          // tiny language icon (top-right)
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.language, color: Colors.black87),
              tooltip: AppLocalizations.of(context)!.selectLanguage,
              onPressed: _showLanguageDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _customButton(String text, Color color, VoidCallback onPressed,
      {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text.rich(
          TextSpan(
            text: text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()..onTap = onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller,
      {bool isPassword = false, Key? key}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 219, 229, 221),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextFormField(
          key: key,
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
