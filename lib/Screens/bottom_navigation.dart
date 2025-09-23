import 'package:agribot/Screens/analytics_screen.dart';
import 'package:agribot/Screens/analytics_screen2.dart';
import 'package:agribot/Screens/disease_detection_screen.dart';
import 'package:agribot/Screens/home_screen.dart';
import 'package:agribot/Screens/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BottomNavigation extends StatefulWidget {
  final void Function(Locale) onChangeLanguage; // ← add this
  final String userEmail;
  const BottomNavigation(
      {required this.userEmail, required this.onChangeLanguage, super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int selectedIndex = 0;
  final PageController pageController = PageController();

  late double iconSize;
  late double fontSize;

  // Build pages after we have access to `widget` (can't access `widget` at field init time).
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomeScreen(onChangeLanguage: widget.onChangeLanguage), // ← pass it
      DiseaseDetectionScreen(
          userEmail: widget.userEmail,
          onChangeLanguage: widget.onChangeLanguage),
      const AnalyticsScreen2(),
      const SettingScreen(), // add a language button here later if you want
    ];
  }

  void onItemTapped(int index) {
    setState(() => selectedIndex = index);
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    iconSize = size.width * 0.065;
    fontSize = size.width * 0.030;

    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) => setState(() => selectedIndex = index),
        children: pages,
        physics: const BouncingScrollPhysics(),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 5,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/Home.png'),
                  size: iconSize),
              label: l10n.navHome, // ← localized
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/upload_svg.png'),
                  size: iconSize),
              label: l10n.navUpload,
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/Chart.png'),
                  size: iconSize),
              label: l10n.navAnalytics,
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/Filter.png'),
                  size: iconSize),
              label: l10n.navControls,
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/Setting_line.png'),
                  size: iconSize),
              label: l10n.navSettings,
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedFontSize: fontSize + 2,
          unselectedFontSize: fontSize,
          onTap: onItemTapped,
        ),
      ),
    );
  }
}
