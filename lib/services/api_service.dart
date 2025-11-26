import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://10.0.2.2:5000/api/auth";
  // use 10.0.2.2 if Android emulator, localhost if web

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

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

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

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔵 Logging in user: $email');
      print('🔵 API URL: $baseUrl/login');

      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 10));

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data['token']); // save JWT
        await prefs.setString(
          "userType",
          data['user']['userType'],
        ); // save user type
        await prefs.setString(
          "userName",
          data['user']['userName'],
        ); // save user name
        print('✅ Login successful, token saved');
      } else {
        throw Exception(data['error'] ?? 'Login failed');
      }

      return data;
    } catch (e) {
      print('❌ Login error: $e');
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        throw Exception(
          'Cannot connect to server. Make sure backend is running on port 5000.',
        );
      }
      rethrow;
    }
  }

  /// 🔹 Forgot Password - Send reset link to email
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      print('🔵 Requesting password reset for: $email');
      print('🔵 API URL: $baseUrl/forgot-password');

      final response = await http
          .post(
            Uri.parse("$baseUrl/forgot-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 10));

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      return {"statusCode": response.statusCode, "data": data};
    } catch (e) {
      print('❌ Forgot password error: $e');
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        return {
          "statusCode": 500,
          "data": {
            "message":
                "Could not connect to server. Make sure backend is running on port 5000.",
          },
        };
      }
      return {
        "statusCode": 500,
        "data": {"message": "Could not connect to server: $e"},
      };
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("userType");
    await prefs.remove("userName");
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<String?> getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("userType");
  }

  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("userName");
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // other existing methods like login, logout, etc.

  /// 🔹 Check if the user logged in for the first time
  Future<bool> isFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    // Default = false means not first login
    return prefs.getBool('isFirstLogin') ?? false;
  }

  /// 🔹 Mark user as having logged in once (so next time it's not first)
  Future<void> markFirstLoginDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLogin', true);
  }

  /// 🔹 Optional: reset flag when user logs out
  Future<void> clearFirstLoginFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isFirstLogin');
  }
}
