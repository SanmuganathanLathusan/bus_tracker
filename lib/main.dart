import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:waygo/screens/HomePage.dart';
import 'package:waygo/screens/signup.dart';
import 'package:waygo/screens/splash.dart';
import 'screens/welcome_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){
  
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAmmTkW8JIGc5b6NKBfJ5AQwyYlQtTs8nQ",
  authDomain: "waygo-cb228.firebaseapp.com",
  projectId: "waygo-cb228",
  storageBucket: "waygo-cb228.firebasestorage.app",
  messagingSenderId: "630363687413",
  appId: "1:630363687413:web:88dff654d695ef877ab8bc",
  measurementId: "G-DCGH3B8EJ1" 
    ), );
  }
  else{
    await Firebase.initializeApp();
  }
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
