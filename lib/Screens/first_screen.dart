import 'package:agribot/Widgets/display_button.dart';
import 'package:agribot/Screens/login_screen.dart';
import 'package:agribot/Screens/register_screen.dart';
import 'package:agribot/utils/font_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FirstScreen extends StatefulWidget {
  final void Function(Locale) onChangeLanguage;
  const FirstScreen({required this.onChangeLanguage, super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  @override
  void initState() {
    super.initState();
    // force language selection on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLanguageDialog();
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
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

  // This function scales the font size based on the device's width.
  double responsiveFontSize(BuildContext context, double baseSize) {
    double baseWidth = MediaQuery.of(context).size.width;
    return baseSize * (baseWidth / 375.0);
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;

    final lines = AppLocalizations.of(context)!.tagline_multiline.split('\n');

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SizedBox(
              height: h,
              width: w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/firstScreenBg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: w * 0.08),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SizedBox(height: h * 0.1),

                        // // 4 lines, same styling — now localized:
                        // Text(
                        //   AppLocalizations.of(context)!.taglineCultivate,
                        //   style: FontHelper.getStyle(
                        //     textColor: Colors.white,
                        //     fontSize: responsiveFontSize(context, 60),
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        // Text(
                        //   AppLocalizations.of(context)!.taglineYourFuture,
                        //   style: FontHelper.getStyle(
                        //     textColor: Colors.white,
                        //     fontSize: responsiveFontSize(context, 60),
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        // Text(
                        //   AppLocalizations.of(context)!.taglineWith,
                        //   style: FontHelper.getStyle(
                        //     textColor: Colors.white,
                        //     fontSize: responsiveFontSize(context, 60),
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        // Text(
                        //   AppLocalizations.of(context)!.taglineAgribot,
                        //   style: FontHelper.getStyle(
                        //     textColor: Colors.white,
                        //     fontSize: responsiveFontSize(context, 60),
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        SizedBox(height: h * 0.1),

                        for (final line in lines)
                          Text(
                            line,
                            style: FontHelper.getStyle(
                              textColor: Colors.white,
                              fontSize: responsiveFontSize(context, 60),
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        const Spacer(),
                        Center(
                          child: Column(
                            children: [
                              DisplayButton(
                                buttonKey: const Key('SignInButton'),
                                text: AppLocalizations.of(context)!
                                    .signIn, // <-- localized
                                bgColor:
                                    const Color.fromARGB(93, 255, 255, 255),
                                radius: 20,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(
                                        onChangeLanguage:
                                            widget.onChangeLanguage,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                key: const Key('CreateAccountLink'),
                                text: TextSpan(
                                  text: AppLocalizations.of(context)!
                                      .createAccount, // <-- localized
                                  style: FontHelper.getStyle(
                                    textColor: Colors.white,
                                    fontSize: responsiveFontSize(context, 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RegisterScreen(
                                            onChangeLanguage:
                                                widget.onChangeLanguage,
                                          ),
                                        ),
                                      );
                                    },
                                  mouseCursor: SystemMouseCursors.click,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: h * 0.05),
                      ]),
                ),
              ),
            ),
          ),
          // tiny icon on top-right to change language later
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.language, color: Colors.white),
              onPressed: _showLanguageDialog,
            ),
          ),
        ],
      ),
    );
  }
}
