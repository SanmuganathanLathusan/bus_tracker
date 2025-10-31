import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();

  String step = "email"; // steps: email → code → reset
  final String baseUrl = "http://localhost:5000/api/auth"; // your backend URL

  Future<void> sendCode() async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": emailController.text}),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Code sent to email")),
      );
      setState(() => step = "code");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Error")),
      );
    }
  }

  Future<void> verifyCode() async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text,
        "code": codeController.text,
      }),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Code verified")),
      );
      setState(() => step = "reset");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Invalid code")),
      );
    }
  }

  Future<void> resetPassword() async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text,
        "newPassword": newPasswordController.text,
      }),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset successful")),
      );
      Navigator.pop(context); // Go back to login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (step == "email") ...[
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Enter your email"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: sendCode,
                child: const Text("Send Code"),
              ),
            ] else if (step == "code") ...[
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: "Enter code from email"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: verifyCode,
                child: const Text("Verify Code"),
              ),
            ] else if (step == "reset") ...[
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Enter new password"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: resetPassword,
                child: const Text("Reset Password"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
