import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waygo/services/api_service.dart';

class NewsService {
  static const String baseUrl = "http://10.0.2.2:5000/api/news";

  Future<String?> _getToken() async {
    return await AuthService().getToken();
  }

  // Get news for passengers (published/active only)
  Future<List<Map<String, dynamic>>> getNews() async {
    try {
      print('🔵 Fetching news...');
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 10));

      print('🔵 News response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch news');
      }
    } catch (e) {
      print('❌ Get news error: $e');
      rethrow;
    }
  }

  // Get all news for admin
  Future<List<Map<String, dynamic>>> getAllNews() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('🔵 Fetching all news (admin)...');
      final response = await http.get(
        Uri.parse("$baseUrl/admin/all"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch news');
      }
    } catch (e) {
      print('❌ Get all news error: $e');
      rethrow;
    }
  }

  // Get news by ID
  Future<Map<String, dynamic>> getNewsById(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse("$baseUrl/admin/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch news');
      }
    } catch (e) {
      print('❌ Get news by ID error: $e');
      rethrow;
    }
  }

  // Create news (admin)
  Future<Map<String, dynamic>> createNews({
    required String title,
    required String description,
    String? imageUrl,
    String type = 'Info',
    String? status,
    String? publishDate,
    String? expiryDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('🔵 Creating news: $title');
      final response = await http.post(
        Uri.parse("$baseUrl/admin"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "description": description,
          "imageUrl": imageUrl,
          "type": type,
          "status": status,
          "publishDate": publishDate,
          "expiryDate": expiryDate,
        }),
      ).timeout(const Duration(seconds: 10));

      print('🔵 Create news response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create news');
      }
    } catch (e) {
      print('❌ Create news error: $e');
      rethrow;
    }
  }

  // Update news (admin)
  Future<Map<String, dynamic>> updateNews({
    required String id,
    String? title,
    String? description,
    String? imageUrl,
    String? type,
    String? status,
    String? publishDate,
    String? expiryDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('🔵 Updating news: $id');
      final response = await http.put(
        Uri.parse("$baseUrl/admin/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          if (title != null) "title": title,
          if (description != null) "description": description,
          if (imageUrl != null) "imageUrl": imageUrl,
          if (type != null) "type": type,
          if (status != null) "status": status,
          if (publishDate != null) "publishDate": publishDate,
          if (expiryDate != null) "expiryDate": expiryDate,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update news');
      }
    } catch (e) {
      print('❌ Update news error: $e');
      rethrow;
    }
  }

  // Delete news (admin)
  Future<void> deleteNews(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('🔵 Deleting news: $id');
      final response = await http.delete(
        Uri.parse("$baseUrl/admin/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete news');
      }
    } catch (e) {
      print('❌ Delete news error: $e');
      rethrow;
    }
  }
}

