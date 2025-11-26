import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Controller to handle email text input
  final TextEditingController emailController = TextEditingController();

  // AuthService API instance
  final AuthService _authService = AuthService();

  // UI state variables
  bool isLoading = false;
  String? successMessage;

  // Function to send reset email (Backend call)
  Future<void> sendResetEmail() async {
    final email = emailController.text.trim(); // Clean whitespace

    // If no email entered → show warning
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    // Start loading & clear previous message
    setState(() {
      isLoading = true;
      successMessage = null;
    });

    // API call to backend
    final result = await _authService.forgotPassword(email: email);

    // Extract message from response
    final message = result['data']['message'] ?? 'Failed to send reset link';

    // Stop loading indicator
    setState(() => isLoading = false);

    // Check success conditions (statusCode OR response text)
    final isSuccess = result['statusCode'] == 200 ||
        message.toLowerCase().contains('success') ||
        message.toLowerCase().contains('sent');

    // Update visible message
    setState(() {
      successMessage = isSuccess
          ? "✅ Reset link sent! Please check your email inbox (and spam folder)."
          : "❌ Failed to send reset link. Try again.";
    });
