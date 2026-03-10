import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:waygo/user_screen/user_pages.dart';
import 'package:waygo/user_screen/pages/pages.dart';
import 'package:waygo/admin_screen/admin_pages.dart';
import 'package:waygo/driver_screen/driver_pages.dart';

void main() {
  Stripe.publishableKey =
      'pk_test_51SU6ZjF3HPXggBggcZjc2M9KhXNMymVXveo6HhKzRqzMtmzOX1CiLUEwDByUNN3XbZUGfGdhRwebp8rc9cfPoB1400pHxV9q8O';

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
      ),

      initialRoute: '/',

      routes: {

        /// Auth & Intro
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),

        /// Dashboards
        '/passenger-dashboard': (context) => const PassengerDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/driver-dashboard': (context) => const DriverDashboard(),

        /// App Features
        '/news': (context) => const MainNews(),
        '/live_location': (context) => const LiveLocationPage(),
        '/schedule': (context) => const SchedulePage(),
        '/seats': (context) => const SeatReservationHome(),
        '/prices': (context) => const TicketPricesPage(),
        '/eticket': (context) => const EticketBookingPage(),
      },
    );
  }
}