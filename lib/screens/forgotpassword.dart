import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String step = "email"; // email -> code -> reset
  final String baseUrl = "http://localhost:5000/api/auth"; // Backend URL

  Future<void> sendCode() async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": emailController.text}),
    );
    final data = jsonDecode(response.body);

    _showSnackBar(response.statusCode == 200
        ? "Reset code sent to your email"
        : (data["message"] ?? "Error sending code"));
    if (response.statusCode == 200) setState(() => step = "code");
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

    _showSnackBar(response.statusCode == 200
        ? "Code verified"
        : (data["message"] ?? "Invalid code"));
    if (response.statusCode == 200) setState(() => step = "reset");
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

    _showSnackBar(response.statusCode == 200
        ? "Password reset successfully!"
        : (data["message"] ?? "Error resetting password"));
    if (response.statusCode == 200) Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          "Forgot Password",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.directions_bus, size: 80, color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              step == "email"
                  ? "Enter your registered email"
                  : step == "code"
                      ? "Enter the code sent to your email"
                      : "Enter your new password",
              style: GoogleFonts.poppins(
                  fontSize: 16, color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 32),

            if (step == "email") ..._emailInput(),
            if (step == "code") ..._codeInput(),
            if (step == "reset") ..._resetInput(),
          ],
        ),
      ),
    );
  }

  List<Widget> _emailInput() => [
        _buildTextField(
          controller: emailController,
          label: "Email Address",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        _buildButton("Send Reset Code", sendCode),
      ];

  List<Widget> _codeInput() => [
        _buildTextField(
          controller: codeController,
          label: "Verification Code",
          icon: Icons.security,
        ),
        const SizedBox(height: 20),
        _buildButton("Verify Code", verifyCode),
      ];

  List<Widget> _resetInput() => [
        _buildTextField(
          controller: newPasswordController,
          label: "New Password",
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 20),
        _buildButton("Reset Password", resetPassword),
      ];

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
