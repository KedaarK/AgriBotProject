import 'package:agribot/Services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:agribot/Screens/register_screen.dart';
import 'package:agribot/Widgets/display_button.dart';
import 'package:agribot/utils/font_helper.dart';
import 'package:agribot/Screens/bottom_navigation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final void Function(Locale) onChangeLanguage;
  const LoginScreen({required this.onChangeLanguage, super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  double bottomPosition = -1000; // Initially hidden below screen

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        bottomPosition = 0; // Bring up the login container
      });
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
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

  void _login() async {
    final l10n = AppLocalizations.of(context)!;
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterAllDetails)),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidEmail)),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await AuthService().signin(
        email: email,
        password: password,
        context: context,
        onChangeLanguage: widget.onChangeLanguage,
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      // Navigate to Bottom Navigation Screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => BottomNavigation(
                    userEmail: email,
                    onChangeLanguage: widget.onChangeLanguage,
                  )),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog on failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginFailed(e.toString()))),
      );
    }
  }

  bool _isValidEmail(String email) {
    const emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    return RegExp(emailPattern).hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: const Key('LoginScreen'),
      body: SizedBox(
        height: screenHeight,
        width: screenWidth,
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/firstScreenBg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Tiny language icon (top-right), same as FirstScreen
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                onPressed: _showLanguageDialog,
                tooltip: l10n.selectLanguage,
              ),
            ),

            // Animated Login Container
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: bottomPosition,
              child: Container(
                height: (1.12 * screenHeight) / 2,
                width: screenWidth,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      l10n.welcomeBack, // "Welcome Back"
                      style: FontHelper.getStyle(
                        textColor: const Color.fromARGB(255, 70, 116, 75),
                        fontSize: screenWidth * 0.14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.loginToYourAccount, // "Login to your Account"
                      style: FontHelper.getStyle(
                        textColor: const Color.fromARGB(255, 192, 192, 192),
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email
                    _buildTextField(
                      emailController,
                      l10n.emailLabel, // localized label
                      isEmail: true,
                      fieldKey: const Key('EmailField'),
                    ),

                    // Password
                    _buildTextField(
                      passwordController,
                      l10n.passwordLabel, // localized label
                      isPassword: true,
                      fieldKey: const Key('PasswordField'),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 36, bottom: 24),
                          child: Text(
                            l10n.rememberMe,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 192, 192, 192),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 36, bottom: 24),
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 70, 116, 75),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Login Button
                    DisplayButton(
                      buttonKey: const Key('LoginButton'),
                      bgColor: const Color.fromARGB(255, 70, 116, 75),
                      text: l10n.login,
                      onTap: _login,
                      radius: 30,
                    ),
                    const SizedBox(height: 16),

                    // Sign Up Link
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: l10n.dontHaveAccount + ' ',
                            style: FontHelper.getStyle(
                              fontSize: 16,
                              textColor:
                                  const Color.fromARGB(255, 192, 192, 192),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: l10n.signUp,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 70, 116, 75),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Color.fromARGB(255, 70, 116, 75),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterScreen(
                                        onChangeLanguage:
                                            widget.onChangeLanguage),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Input Field Widget
  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    bool isPassword = false,
    bool isEmail = false,
    Key? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 219, 229, 221),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextFormField(
          key: fieldKey,
          controller: controller,
          obscureText: isPassword,
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.text,
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
