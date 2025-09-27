import 'package:flutter/material.dart';
import 'package:waygo/screens/HomePage.dart';
import 'package:waygo/screens/pages/etickets_page.dart';
import 'package:waygo/screens/pages/live_location_page.dart';
import 'package:waygo/screens/pages/news_page.dart';
import 'package:waygo/screens/pages/schedule_page.dart';
import 'package:waygo/screens/pages/seat_reservation_page.dart';
import 'package:waygo/screens/pages/ticket_prices_page.dart';
import 'package:waygo/screens/signup.dart';
import 'package:waygo/screens/splash.dart';
import 'package:waygo/screens/welcome_screen.dart';

// import your new dashboard pages


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
        primarySwatch: Colors.blue, // later replace with AppColors
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(),

        // dashboard routes
        '/news': (context) => const MainNews(),
        '/live_location': (context) => const LiveLocation(),
        '/schedule': (context) => const Schedule(),
        '/seats': (context) => const SeatReservation(),
        '/prices': (context) => const TicketPrices(),
        '/eticket': (context) => const Etickets(),
      },
    );
  }
}
