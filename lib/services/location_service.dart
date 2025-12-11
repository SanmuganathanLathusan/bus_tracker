import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waygo/services/api_service.dart';

class LocationService {
  static const String baseUrl = "http://10.0.2.2:5000/api";
  static const Duration _timeout = Duration(seconds: 10);

  final AuthService _authService = AuthService();

  Future<String?> _getToken() => _authService.getToken();

  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
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

  /// Get all buses with their locations for a specific route
  Future<List<Map<String, dynamic>>> getBusesForRoute(
    String routeId,
    String date,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse(
        "$baseUrl/routes/search?start=&destination=&date=$date",
      );
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (data is List) {
        // Filter for the specific route
        final routeData = data.firstWhere(
          (route) => route['route'] is Map && route['route']['_id'] == routeId,
          orElse: () => <String, dynamic>{},
        );

        if (routeData.isEmpty) {
          return [];
        }

        final assignments = routeData['assignments'] as List? ?? [];
        final result = <Map<String, dynamic>>[];

        for (var assignment in assignments) {
          if (assignment is Map && assignment['busId'] is Map) {
            final bus = assignment['busId'] as Map;
            final driver = assignment['driverId'] as Map?;

            result.add({
              'busId': bus['_id'],
              'busNumber': bus['busNumber'],
              'busName': bus['busName'],
              'location': bus['currentLocation'],
              'isLocationSharing': bus['isLocationSharing'] ?? false,
              'driverName': driver != null ? driver['userName'] : 'Unknown',
              'assignmentId': assignment['_id'],
              'scheduledTime': assignment['scheduledTime'],
              'status': assignment['status'],
            });
          }
        }

        return result;
      }

      return [];
    } catch (e) {
      print('❌ Get buses for route error: $e');
      rethrow;
    }
  }

  /// Get specific bus location
  Future<Map<String, dynamic>> getBusLocation(String busId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse("$baseUrl/buses/$busId");
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);

      final data = _decodeResponse(response);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Unexpected bus location response');
    } catch (e) {
      print('❌ Get bus location error: $e');
      rethrow;
    }
  }
}
