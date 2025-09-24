import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assest/images5.webp"),
                fit: BoxFit.cover,
              ),
            ),
          ),


          /// Gradient overlay (0.5 opacity)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.waygoDarkBlue.withOpacity(0.5),
                  AppColors.waygoLightBlue.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          /// Foreground content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Logo (not affected by opacity)
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Image.asset("assest/logo.png", fit: BoxFit.cover),

                ),

                const SizedBox(height: 20),

                /// App name
                const Text(
                  "WayGo",
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                /// Slogan
                const Text(
                  "Travel smart, go further",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                /// Loader
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
