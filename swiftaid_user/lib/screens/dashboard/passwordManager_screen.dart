// lib/screens/settings/password_manager_screen.dart
import 'package:flutter/material.dart';

class PasswordManagerScreen extends StatefulWidget {
  const PasswordManagerScreen({super.key});

  @override
  State<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _obscure3 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Password Manager"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔐 Current Password
            TextField(
              controller: _currentController,
              obscureText: _obscure1,
              decoration: InputDecoration(
                hintText: "Current Password",
                suffixIcon: IconButton(
                  icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 🔐 New Password
            TextField(
              controller: _newController,
              obscureText: _obscure2,
              decoration: InputDecoration(
                hintText: "New Password",
                suffixIcon: IconButton(
                  icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 🔐 Confirm New Password
            TextField(
              controller: _confirmController,
              obscureText: _obscure3,
              decoration: InputDecoration(
                hintText: "Confirm New Password",
                suffixIcon: IconButton(
                  icon: Icon(_obscure3 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure3 = !_obscure3),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to forgot password
                },
                child: const Text("Forgot Password?"),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // TODO: Handle password change
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
              child: const Text("Change Password"),
            )
          ],
        ),
      ),
    );
  }
}
