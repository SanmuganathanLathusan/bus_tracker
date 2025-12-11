import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:waygo/services/api_service.dart';

class MaintenanceService {
  MaintenanceService();

  static const String _baseUrl = "http://10.0.2.2:5000/api/maintenance";
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

  // Create maintenance report with image
  Future<Map<String, dynamic>> createReport({
    required String busId,
    required String issueType,
    required String description,
    File? imageFile,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/");
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(token));
    
    request.fields['busId'] = busId;
    request.fields['issueType'] = issueType;
    request.fields['description'] = description;

    if (imageFile != null && await imageFile.exists()) {
      final fileName = imageFile.path.split('/').last;
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: fileName,
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decodeResponse(response);
    
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response format');
  }

  // Submit report to admin
  Future<Map<String, dynamic>> submitReport(String reportId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/$reportId/submit");
    final response = await http
        .post(uri, headers: {
          ..._headers(token),
          "Content-Type": "application/json",
        })
        .timeout(_timeout);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response format');
  }

  // Get driver's reports
  Future<List<dynamic>> getDriverReports() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/my-reports");
    final response =
        await http.get(uri, headers: {
          ..._headers(token),
          "Content-Type": "application/json",
        }).timeout(_timeout);

    final data = _decodeResponse(response);
    if (data is List) return data;
    return [];
  }

  // Get all reports (admin)
  Future<List<dynamic>> getAllReports({String? status}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/admin/all").replace(
      queryParameters: status != null ? {'status': status} : {},
    );
    final response =
        await http.get(uri, headers: {
          ..._headers(token),
          "Content-Type": "application/json",
        }).timeout(_timeout);

    final data = _decodeResponse(response);
    if (data is List) return data;
    return [];
  }

  // Update report status (admin)
  Future<Map<String, dynamic>> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/admin/$reportId/status");
    final response = await http
        .put(
          uri,
          headers: {
            ..._headers(token),
            "Content-Type": "application/json",
          },
          body: jsonEncode({'status': status}),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response format');
  }
}

