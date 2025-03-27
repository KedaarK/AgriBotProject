import 'package:agribot/Services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:agribot/Screens/register_screen.dart';
import 'package:agribot/Widgets/display_button.dart';
import 'package:agribot/utils/font_helper.dart';
import 'package:agribot/Screens/bottom_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all details")),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address")),
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
      );

      Navigator.pop(context); // Close loading dialog

      // Navigate to Bottom Navigation Screen
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                BottomNavigation()), // Replace with your Bottom Navigation Screen
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog on failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  // Email Validation Function
  bool _isValidEmail(String email) {
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    return RegExp(emailPattern).hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SizedBox(
        height: h,
        width: w,
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/firstScreenBg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
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
                height: (1.12 * h) / 2,
                width: w,
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
                      'Welcome Back',
                      style: FontHelper.getStyle(
                        textColor: const Color.fromARGB(255, 70, 116, 75),
                        fontSize: 52,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Login to your Account',
                      style: FontHelper.getStyle(
                        textColor: const Color.fromARGB(255, 192, 192, 192),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Input Field
                    _buildTextField(emailController, "Email", isEmail: true),

                    // Password Input Field
                    _buildTextField(passwordController, "Password",
                        isPassword: true),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 36, bottom: 24),
                          child: Text(
                            'Remember Me',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 192, 192, 192),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 36, bottom: 24),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
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
                      bgColor: const Color.fromARGB(255, 70, 116, 75),
                      text: 'Login',
                      onTap: _login,
                      radius: 30,
                    ),
                    const SizedBox(height: 16),

                    // Sign Up Link
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Don\'t Have an Account? ',
                            style: FontHelper.getStyle(
                              fontSize: 16,
                              textColor:
                                  const Color.fromARGB(255, 192, 192, 192),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: 'Sign Up',
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
                                      builder: (context) =>
                                          const RegisterScreen()),
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
  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool isPassword = false, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 219, 229, 221),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            labelText: labelText, // Label text that moves up on focus
            labelStyle: const TextStyle(
              color: Color.fromARGB(255, 70, 116, 75),
              fontWeight: FontWeight.w500,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.green,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}
