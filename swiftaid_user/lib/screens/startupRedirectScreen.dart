import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './dashboard/main_tabs.dart'; // or wherever your MainTabs screen is
import './onboarding/splash_screen.dart';

class StartupRedirectScreen extends StatefulWidget {
  const StartupRedirectScreen({super.key});

  @override
  State<StartupRedirectScreen> createState() => _StartupRedirectScreenState();
}

class _StartupRedirectScreenState extends State<StartupRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserLogin();
  }

  Future<void> _checkUserLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token != null && token.isNotEmpty) {
      // User is logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainTabs()),
      );
    } else {
      // User not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
