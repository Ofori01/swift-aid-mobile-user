import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme_provider.dart';
import './passwordManager_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Toggle
          SwitchListTile(
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.brightness_6),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (val) {
              themeProvider.toggleTheme(val);
            },
          ),
          const Divider(),

          // Notification Settings
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Notification Settings"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),

          // 🔐 Password Manager
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text("Password Manager"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const PasswordManagerScreen())
              );
      },
          ),

          // Delete Account
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text("Delete Account"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Show delete confirmation
            },
          ),
        ],
      ),
    );
  }
}
