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

    // Smooth page transition
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        children: pages,
        physics: const BouncingScrollPhysics(), // Adds bounce effect
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
              ),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/Chart.png'),
              ),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/Home.png'),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/Filter.png'),
              ),
              label: 'Controls',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(
                AssetImage('assets/images/Setting_line.png'),
              ),
              label: 'Settings',
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          onTap: onItemTapped,
        ),
      ),
    );
  }
}
