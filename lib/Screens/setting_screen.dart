import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool pushNotifications = true;
  bool darkMode = false;

  void _toggleTheme() {
    // Logic to toggle dark mode (You can integrate Theme switching here)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 92),
          child: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ACCOUNT SETTINGS HEADER
          const Text(
            "Account Settings",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          // SETTINGS OPTIONS
          _buildListTile("Edit profile", Icons.person, () {}),
          _buildListTile("Change password", Icons.lock, () {}),
          _buildListTile("Add a payment method", Icons.add, () {},
              isIconTrailing: true),

          const Divider(),

          // SWITCH SETTINGS
          SwitchListTile(
            title: const Text("Push notifications"),
            value: pushNotifications,
            activeColor: Colors.green,
            onChanged: (value) {
              setState(() {
                pushNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text("Dark mode"),
            value: darkMode,
            activeColor: Colors.green,
            onChanged: (value) {
              setState(() {
                darkMode = value;
                _toggleTheme();
              });
            },
          ),

          const Divider(),

          // MORE SETTINGS HEADER
          const Text(
            "More",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          _buildListTile("Logout", Icons.exit_to_app, () {
            print("Logout");
          }),
          _buildListTile("About us", Icons.info, () {}),
          _buildListTile("Privacy policy", Icons.privacy_tip, () {}),
          _buildListTile("Terms and conditions", Icons.description, () {}),
        ],
      ),
    );
  }

  // FUNCTION TO CREATE LIST TILES
  Widget _buildListTile(String title, IconData icon, Function onTap,
      {bool isIconTrailing = false}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      leading: Icon(icon, color: Colors.black),
      trailing: isIconTrailing
          ? const Icon(Icons.add, color: Colors.black)
          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
      onTap: () {
        onTap();
      },
    );
  }
}
