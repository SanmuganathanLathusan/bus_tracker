import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  // Sends user information to the server to create a new account

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

 // Handles API request for user authentication using provided login credentials

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

 // API call to initiate the password reset process by sending the user's email to the server

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
