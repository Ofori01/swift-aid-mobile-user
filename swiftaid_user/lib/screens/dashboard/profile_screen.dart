import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftaid_user/screens/onboarding/onboarding_screens.dart';
import './settings_screen.dart'; 
import './main_tabs.dart'; 
import './privacyPolicy_screen.dart'; 
import './profileDetails_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('userName') ?? '';
      email = prefs.getString('userEmail') ?? '';
      phone = prefs.getString('userPhone') ?? '';
    });
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Top Section ---
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainTabs()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "My Profile",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.red.shade200,
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(phone),
                  Text(email),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(icon: Icons.person, title: "Profile", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()),
                    );
                  }),
                  _buildMenuItem(icon: Icons.lock, title: "Privacy Policy", onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())
                    );
                  }),
                  _buildMenuItem(icon: Icons.settings, title: "Settings", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  }),
                  _buildMenuItem(icon: Icons.help, title: "Help", onTap: () {}),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: "Logout",
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Logout"),
                          content: const Text("Are you sure you want to logout?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout")),
                          ],
                        ),
                      );

                      if (shouldLogout ?? false) {
                        await logout(context);
                      }
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}