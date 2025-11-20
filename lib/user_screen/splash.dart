import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    // Wait for splash screen to show for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();
      
      if (isLoggedIn) {
        final userType = await authService.getUserType();
        String route;
        
        switch (userType) {
          case 'passenger':
            route = '/passenger-dashboard';
            break;
          case 'driver':
            route = '/driver-dashboard';
            break;
          case 'admin':
            route = '/admin-dashboard';
            break;
          default:
            route = '/welcome';
        }
        
        Navigator.pushReplacementNamed(context, route);
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      // If there's any error, go to welcome screen
      Navigator.pushReplacementNamed(context, '/welcome');
    }
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
