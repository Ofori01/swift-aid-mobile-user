import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Last Update: 14/08/2024", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque ut diam congue lorem...",
              ),
              SizedBox(height: 20),
              Text("Terms & Conditions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 10),
              Text("1. Ut lacinia justo sit amet lorem sodales accumsan..."),
              Text("2. Donec condimentum, nunc at rhoncus faucibus..."),
              Text("3. Lorem ipsum dolor sit amet, consectetur..."),
              Text("4. Aenean arcu metus, bibendum at rhoncus at..."),
            ],
          ),
        ),
      ),
    );
  }
}
