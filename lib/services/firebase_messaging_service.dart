import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📱 Background message: ${message.messageId}');
  debugPrint('📱 Data: ${message.data}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('✅ FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        debugPrint('✅ FCM Token: $_fcmToken');

        // Listen to token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 FCM Token refreshed: $newToken');
          _fcmToken = newToken;
          _updateTokenOnServer(newToken);
        });

        // Setup message handlers
        _setupMessageHandlers();
      } else {
        debugPrint('⚠️  Notification permission denied');
      }
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  /// Setup message handlers for foreground and background
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Foreground message received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // You can show a local notification here if needed
      _handleMessage(message);
    });

    // Message opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 Notification opened');
      debugPrint('Data: ${message.data}');
      _handleMessage(message);
    });

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Check if app was opened from a terminated state
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 App opened from terminated state');
        _handleMessage(message);
      }
    });
  }

  /// Handle incoming message
  void _handleMessage(RemoteMessage message) {
    final data = message.data;

    // Handle different message types
    if (data.containsKey('assignmentId')) {
      debugPrint('📋 Assignment notification: ${data['assignmentId']}');
      // Navigate to assignments screen or show dialog
    } else if (data.containsKey('reservationId')) {
      debugPrint('🎫 Reservation notification: ${data['reservationId']}');
      // Handle passenger booking notification
    }
  }

  /// Send FCM token to backend
  Future<bool> sendTokenToServer() async {
    if (_fcmToken == null) {
      debugPrint('⚠️  No FCM token available');
      return false;
    }

    return _updateTokenOnServer(_fcmToken!);
  }

  Future<bool> _updateTokenOnServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      final baseUrl = prefs.getString('base_url') ?? 'http://10.0.2.2:5000';

      if (authToken == null) {
        debugPrint('⚠️  No auth token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token sent to server');
        return true;
      } else {
        debugPrint('❌ Failed to send FCM token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM token: $e');
      return false;
    }
  }

  /// Remove FCM token from server (on logout)
  Future<void> removeTokenFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      final baseUrl = prefs.getString('base_url') ?? 'http://10.0.2.2:5000';

      if (authToken == null) return;

      await http.delete(
        Uri.parse('$baseUrl/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'fcmToken': _fcmToken}),
      );

      debugPrint('✅ FCM token removed from server');
    } catch (e) {
      debugPrint('❌ Error removing FCM token: $e');
    }
  }

  /// Subscribe to topic (optional, for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}
