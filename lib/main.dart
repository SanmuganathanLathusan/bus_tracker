import 'package:flutter/material.dart';
import 'package:waygo/screens/HomePage.dart';
import 'package:waygo/screens/signup.dart';
import 'package:waygo/screens/splash.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth Flow',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignUpScreen(),
         '/home': (context) => const HomePage(),
      },
    );
  }
}
