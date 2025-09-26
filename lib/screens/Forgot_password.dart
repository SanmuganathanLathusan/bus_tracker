import 'package:flutter/material.dart';

 class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailController=TextEditingController();
  @override
  void dispose() {
    _emailController.dispose();
    // TODO: implement dispose
    super.dispose();
  }

    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Text("Enter your email and  we will sent you a password reset link",
          textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 10),
        // Email TextField
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: "Email Address",
                      hintStyle: const TextStyle(color: Color.fromARGB(179, 2, 62, 92)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                   SizedBox(height: 10),
                  MaterialButton(onPressed:(){},
                  child: Text("Reset Password"),
                  color:Colors.deepPurple,
                  )
      ],)
    );
  }
}