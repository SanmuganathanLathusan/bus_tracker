import 'package:flutter/material.dart';

// Screens
import 'screens/HomePage.dart';
import 'screens/pages/etickets_page.dart';
import 'screens/pages/live_location_page.dart';
import 'screens/pages/news_page.dart';
import 'screens/pages/schedule_page.dart';
import 'screens/pages/seat_reservation_page.dart';
import 'screens/pages/ticket_prices_page.dart';
import 'screens/signup.dart';
import 'screens/splash.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/forgotpassword.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WayGo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/welcome': (context) => const WelcomeScreen(),

        '/home': (context) => const HomePage(),
        '/news': (context) => const MainNews(),
        '/live_location': (context) => const LiveLocationPage(),
        '/schedule': (context) => const Schedule(),
        '/seats': (context) => const SeatReservation(),
        '/prices': (context) => const TicketPrices(),
        '/eticket': (context) => const Etickets(),
        
        '/forgot_password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}
