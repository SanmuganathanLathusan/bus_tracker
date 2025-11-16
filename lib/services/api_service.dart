import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.42.38:5000/api';

  // Register user
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );
      final data = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": data};
    } catch (e) {
      return {"statusCode": 500, "data": {"message": "Could not connect to server: $e"}};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      final data = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": data};
    } catch (e) {
      return {"statusCode": 500, "data": {"message": "Could not connect to server: $e"}};
    }
  }

  // Forgot password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      final data = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": data};
    } catch (e) {
      return {"statusCode": 500, "data": {"message": "Could not connect to server: $e"}};
    }
  }
}
