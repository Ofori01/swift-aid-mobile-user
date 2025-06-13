import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../models/signup_data.dart';
import 'signup_step4_terms.dart';

class SignupStep3GhanaCard extends StatefulWidget {
  final SignupData signupData;

  const SignupStep3GhanaCard({super.key, required this.signupData});

  @override
  State<SignupStep3GhanaCard> createState() => _SignupStep3GhanaCardState();
}

class _SignupStep3GhanaCardState extends State<SignupStep3GhanaCard> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  File? frontImage;
  File? backImage;

  Future<void> _pickImage(bool isFront) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        content: const Text("Choose how to upload the Ghana Card image."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery"),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        if (isFront) {
          frontImage = File(picked.path);
          widget.signupData.ghanaCardFrontImagePath = picked.path;
        } else {
          backImage = File(picked.path);
          widget.signupData.ghanaCardBackImagePath = picked.path;
        }
      });
    }
  }


  void _continue() {
    if (_formKey.currentState!.validate() &&
        frontImage != null &&
        backImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignupStep4Terms(signupData: widget.signupData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and upload images")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Step 3 of 4")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Enter Ghana Card Info",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Ghana Card Number",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => widget.signupData.ghanaCardNumber = value,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              const Text("Upload Ghana Card Front Image"),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(true),
                child: frontImage == null
                    ? Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(child: Text("Tap to upload front")),
                      )
                    : Image.file(frontImage!, height: 150),
              ),

              const SizedBox(height: 24),
              const Text("Upload Ghana Card Back Image"),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: backImage == null
                    ? Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(child: Text("Tap to upload back")),
                      )
                    : Image.file(backImage!, height: 150),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
