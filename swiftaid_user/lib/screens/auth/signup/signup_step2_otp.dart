import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pin_code_fields/pin_code_fields.dart'; // <-- Import this package
import '../../../models/signup_data.dart';
import 'signup_step3_ghanacard.dart';

class SignupStep2Otp extends StatefulWidget {
  final SignupData signupData;

  const SignupStep2Otp({super.key, required this.signupData});

  @override
  State<SignupStep2Otp> createState() => _SignupStep2OtpState();
}

class _SignupStep2OtpState extends State<SignupStep2Otp> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // _sendOtp(); // Optional: Uncomment if you want to send OTP automatically
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("https://swift-aid-backend.onrender.com/otp/send-otp"),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP sent to ${widget.signupData.phoneNumber}")),
        );
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send OTP: ${data['error']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error sending OTP")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit code")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("https://swift-aid-backend.onrender.com/otp/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": code}),
      );
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['status'] == 'approved') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SignupStep3GhanaCard(signupData: widget.signupData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incorrect OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error verifying OTP")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Step 2 of 4")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Enter the 6-digit code sent to\n${widget.signupData.phoneNumber}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              keyboardType: TextInputType.number,
              autoFocus: true,
              animationType: AnimationType.fade,
              animationDuration: const Duration(milliseconds: 300),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.white,
                selectedFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                activeColor: Colors.red,
                selectedColor: Colors.red,
                inactiveColor: Colors.grey,
              ),
              enableActiveFill: true,
              onChanged: (value) {},
              onCompleted: (value) {
                _otpController.text = value;
                _verifyOtp(); // auto-verify when complete
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify & Continue"),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _secondsRemaining == 0 ? _sendOtp : null,
              child: Text(
                _secondsRemaining == 0
                    ? "Resend code"
                    : "Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
