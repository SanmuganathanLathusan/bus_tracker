import 'package:flutter/material.dart';
import 'package:waygo/user_screen/HomePage.dart';
import 'package:waygo/user_screen/forgotpassword.dart';
import 'package:waygo/user_screen/passenger_dashboard.dart';
import 'package:waygo/user_screen/pages/etickets_page.dart';
import 'package:waygo/user_screen/pages/live_location_page.dart';
import 'package:waygo/user_screen/pages/news_page.dart';
import 'package:waygo/user_screen/pages/schedule_page.dart';
import 'package:waygo/user_screen/pages/seat_reserve/seat_reservation_home.dart';
import 'package:waygo/user_screen/pages/ticket_prices_page.dart';
import 'package:waygo/user_screen/signup.dart';
import 'package:waygo/user_screen/splash.dart';
import 'package:waygo/user_screen/welcome_screen.dart';
import 'package:waygo/admin_screen/admin_dashboard.dart';
import 'package:waygo/driver_screen/driver_dashboard.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

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
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),

        // Role-based dashboards
        '/passenger-dashboard': (context) => const PassengerDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/driver-dashboard': (context) => const DriverDashboard(),

        // dashboard routes
        '/news': (context) => const MainNews(),
        '/live_location': (context) => const LiveLocationPage(),
        '/schedule': (context) => const Schedule(),
        '/seats': (context) => const SeatReservationHome(),
        '/prices': (context) => const TicketPrices(), 
        '/eticket': (context) => ETicketPage(reservationId: ''), 
      },
    );
  }
}
