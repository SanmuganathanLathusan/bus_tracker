import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey =
      'pk_test_51SU6ZjF3HPXggBggcZjc2M9KhXNMymVXveo6HhKzRqzMtmzOX1CiLUEwDByUNN3XbZUGfGdhRwebp8rc9cfPoB1400pHxV9q8O';

  runApp(const WayGoApp());
}

class WayGoApp extends StatelessWidget {
  const WayGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WayGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}