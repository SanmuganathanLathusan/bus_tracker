import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:waygo/services/api_service.dart';

class ProfileService {
  static const String baseUrl = "http://10.0.2.2:5000/api/auth";
  static const Duration _timeout = Duration(seconds: 15);

  final AuthService _authService = AuthService();

  Future<String?> _getToken() => _authService.getToken();

  Map<String, String> _headers(String token) => {
    "Authorization": "Bearer $token",
  };

  dynamic _decodeResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body is Map && body['error'] != null
        ? body['error']
        : 'Request failed (${response.statusCode})';
    throw Exception(message);
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$baseUrl/profile");
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(_timeout);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected profile response');
  }

  /// Update user profile with optional image
  Future<Map<String, dynamic>> updateProfile({
    String? userName,
    String? phone,
    String? licenseNumber,
    File? profileImage,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$baseUrl/profile");
    final request = http.MultipartRequest('PUT', uri);

    // Add authorization header
    request.headers['Authorization'] = 'Bearer $token';

    // Add text fields
    if (userName != null && userName.isNotEmpty) {
      request.fields['userName'] = userName;
    }
    if (phone != null && phone.isNotEmpty) {
      request.fields['phone'] = phone;
    }
    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      request.fields['licenseNumber'] = licenseNumber;
    }

    // Add profile image if provided
    if (profileImage != null) {
      final fileExtension = profileImage.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(fileExtension);

      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected update response');
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
