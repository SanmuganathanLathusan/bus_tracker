import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://10.0.2.2:5000/api/auth";

  // ---------------- REGISTER ----------------
  Future<Map<String, dynamic>> register({
    required String userType,
    required String userName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Registering user: $email');

      final response = await http
          .post(
            Uri.parse("$baseUrl/register"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "userType": userType,
              "userName": userName,
              "phone": phone,
              "email": email,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('🔵 Response: ${response.statusCode} ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(data['error'] ?? 'Registration failed');
      }

      return data;
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  // ---------------- LOGIN ----------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔵 Logging in user: $email');

      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 10));

      print('🔵 Response: ${response.statusCode} ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data['token']);
        await prefs.setString("userType", data['user']['userType']);
        await prefs.setString("userName", data['user']['userName']);
        print('✅ Login successful');
      } else {
        throw Exception(data['error'] ?? 'Login failed');
      }

      return data;
    } catch (e) {
      print('❌ Login error: $e');

      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        throw Exception("Cannot connect to server. Is backend running?");
      }

      rethrow;
    }
  }

  // ---------------- FORGOT PASSWORD ----------------
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      print('🔵 Requesting password reset for: $email');

      final response = await http
          .post(
            Uri.parse("$baseUrl/forgot-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 10));

      print('🔵 Response: ${response.statusCode} ${response.body}');
      final data = jsonDecode(response.body);

      return {
        "statusCode": response.statusCode,
        "data": data,
      };
    } catch (e) {
      print('❌ Forgot password error: $e');

      return {
        "statusCode": 500,
        "data": {
          "message": "Could not connect to server. Is backend running?",
        }
      };
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("userType");
    await prefs.remove("userName");
  }

  Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString("token");

  Future<String?> getUserType() async =>
      (await SharedPreferences.getInstance()).getString("userType");

  Future<String?> getUserName() async =>
      (await SharedPreferences.getInstance()).getString("userName");

  Future<bool> isLoggedIn() async => (await getToken()) != null;

  // ---------------- FIRST LOGIN HANDLING ----------------
  Future<bool> isFirstLogin() async {
    return (await SharedPreferences.getInstance())
            .getBool('isFirstLogin') ??
        false;
  }

  Future<void> markFirstLoginDone() async {
    await (await SharedPreferences.getInstance())
        .setBool('isFirstLogin', true);
  }

  Future<void> clearFirstLoginFlag() async {
    await (await SharedPreferences.getInstance()).remove('isFirstLogin');
  }
}
