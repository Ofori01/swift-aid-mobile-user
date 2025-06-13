import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../../../models/signup_data.dart';
import '../../../screens/auth/login_screen.dart';

class SignupStep4Terms extends StatefulWidget {
  final SignupData signupData;

  const SignupStep4Terms({super.key, required this.signupData});

  @override
  State<SignupStep4Terms> createState() => _SignupStep4TermsState();
}

class _SignupStep4TermsState extends State<SignupStep4Terms> {
  bool agreed = false;
  bool isSubmitting = false;

  Future<void> _submitSignup() async {
    if (!agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must agree to the Terms & Conditions")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final uri = Uri.parse("http://10.0.2.2:8080/user/signup"); // For emulator
      final request = http.MultipartRequest("POST", uri);

      request.fields['name'] = widget.signupData.fullName;
      request.fields['email'] = widget.signupData.email;
      request.fields['phone_number'] = widget.signupData.phoneNumber;
      request.fields['password'] = widget.signupData.password;
      request.fields['ghana_card_number'] = widget.signupData.ghanaCardNumber;

      final frontFile = File(widget.signupData.ghanaCardFrontImagePath!);
      final backFile = File(widget.signupData.ghanaCardBackImagePath!);

      request.files.add(await http.MultipartFile.fromPath(
        'ghana_card_image_front',
        frontFile.path,
        contentType: MediaType.parse(lookupMimeType(frontFile.path) ?? 'image/jpeg'),
        filename: path.basename(frontFile.path),
      ));

      request.files.add(await http.MultipartFile.fromPath(
        'ghana_card_image_back',
        backFile.path,
        contentType: MediaType.parse(lookupMimeType(backFile.path) ?? 'image/jpeg'),
        filename: path.basename(backFile.path),
      ));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${resBody}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting signup: $e")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Step 4 of 4")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Terms & Privacy Policy",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "By creating an account, you agree to our Terms and Conditions and Privacy Policy regarding the use of your data and personal details.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Checkbox(
                  value: agreed,
                  onChanged: (val) => setState(() => agreed = val ?? false),
                ),
                const Expanded(child: Text("I agree to the Terms and Conditions"))
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: isSubmitting ? null : _submitSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size.fromHeight(50),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Account"),
            )
          ],
        ),
      ),
    );
  }
}
