
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
    // Show snackbar regardless of success/failure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          // Scroll to avoid overflow on small screens
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Icon
                    const Icon(
                      Icons.directions_bus_rounded,
                      size: 80,
                      color: Color(0xFF1E88E5),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Enter your email to receive a password reset link',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 30),

                    // 📧 Email input field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 🚀 Send button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        // Disable button while loading
                        onPressed: isLoading ? null : sendResetEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // 🟢 Success or 🔴 Error message
                    if (successMessage != null)
                      Text(
                        successMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: successMessage!.contains('✅')
                              ? Colors.green
                              : Colors.red,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    const SizedBox(height: 15),

                    // 🔙 Go back to login page
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Colors.black54,
                      ),
                      label: const Text(
                        'Back to Login',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clear memory of text controller
    emailController.dispose();
    super.dispose();
  }
}
                    

