import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
     apiKey: "AIzaSyBP4Rn9_MlNGN3wHvJlcpcIizDqEXyiTQA",
      authDomain: "kavi2004812.firebaseapp.com",
      projectId: "kavi2004812",
      storageBucket: "kavi2004812.firebasestorage.app",
      messagingSenderId: "656054437233",
      appId: "1:656054437233:web:620bff28c6d727bc1f62d0",
      measurementId: "G-NVJEGQXSCD",
    );
  }
}
