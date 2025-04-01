import 'package:agribot/Widgets/display_button.dart';
import 'package:agribot/Screens/login_screen.dart';
import 'package:agribot/Screens/register_screen.dart';
import 'package:agribot/utils/font_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: h,
          width: w,
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/firstScreenBg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              padding: EdgeInsets.only(left: w * 0.08), // Dynamic padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: h * 0.1, // Adjusted height based on screen height
                  ),
                  Text(
                    'Cultivate',
                    style: FontHelper.getStyle(
                      textColor: Colors.white,
                      fontSize: w * 0.16, // Adjust font size based on width
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'your future',
                    style: FontHelper.getStyle(
                      textColor: Colors.white,
                      fontSize: w * 0.16, // Adjust font size based on width
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'with',
                    style: FontHelper.getStyle(
                      textColor: Colors.white,
                      fontSize: w * 0.16, // Adjust font size based on width
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'AgriBot',
                    style: FontHelper.getStyle(
                      textColor: Colors.white,
                      fontSize: w * 0.16, // Adjust font size based on width
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    height: h * 0.3, // Adjusted height based on screen height
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DisplayButton(
                        text: 'Sign In',
                        bgColor: const Color.fromARGB(93, 255, 255, 255),
                        radius: 20,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      RichText(
                        text: TextSpan(
                          text: 'Create An Account',
                          style: FontHelper.getStyle(
                            textColor: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                              print("Login Text Clicked");
                            },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
