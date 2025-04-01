import 'package:agribot/Screens/analytics_screen.dart';
import 'package:agribot/Screens/controls_screen.dart';
import 'package:agribot/Screens/disease_detection_screen.dart';
import 'package:agribot/Screens/home_screen.dart';
import 'package:agribot/Screens/setting_screen.dart';
import 'package:flutter/material.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int selectedIndex = 2;
  PageController pageController = PageController();

  late double iconSize;
  late double fontSize;

  List<Widget> pages = [
    DiseaseDetectionScreen(),
    AnalyticsScreen(),
    HomeScreen(),
    ControlsScreen(),
    SettingScreen(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    iconSize = size.width * 0.065;
    fontSize = size.width * 0.030;

    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
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
              icon: ImageIcon(
                AssetImage('assets/images/upload_svg.png'),
                size: iconSize,
              ),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/Chart.png'),
                size: iconSize,
              ),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/Home.png'),
                size: iconSize,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/Filter.png'),
                size: iconSize,
              ),
              label: 'Controls',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/Setting_line.png'),
                size: iconSize,
              ),
              label: 'Settings',
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
