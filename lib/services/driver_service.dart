import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waygo/services/api_service.dart';
import 'package:waygo/driver_screen/widgets/route_assignment.dart';

class DriverService {
  DriverService();

  static const String _baseUrl = "http://10.0.2.2:5000/api/driver";
  static const Duration _timeout = Duration(seconds: 12);

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

  Future<List<RouteAssignment>> getAssignments() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/assignments");
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(_timeout);
    final data = _decodeResponse(response);

    if (data is List) {
      return data
          .map(
            (e) => RouteAssignment.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }
    return [];
  }

  Future<RouteAssignment> respondToAssignment({
    required String assignmentId,
    required RouteStatus status,
    String? responseNote,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/assignments/respond");
    final payload = jsonEncode({
      "assignmentId": assignmentId,
      "status": status.name,
      if (responseNote != null && responseNote.isNotEmpty)
        "response": responseNote,
    });

    final response = await http
        .post(uri, headers: _headers(token), body: payload)
        .timeout(_timeout);

    final data = _decodeResponse(response);
    if (data is Map && data['assignment'] is Map) {
      return RouteAssignment.fromJson(
        Map<String, dynamic>.from(data['assignment']),
      );
    }
    throw Exception('Unexpected response for assignment update');
  }

  Future<Map<String, dynamic>> getAssignmentPassengers(
    String assignmentId,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/assignments/$assignmentId/passengers");
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(_timeout);
    final data = _decodeResponse(response);

    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected passengers payload');
  }

  // Start a trip from an assignment
  Future<Map<String, dynamic>> startTrip(String assignmentId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/trip/start");
    final payload = jsonEncode({"assignmentId": assignmentId});

    final response = await http
        .post(uri, headers: _headers(token), body: payload)
        .timeout(_timeout);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected trip start response');
  }

  // End/Complete a trip
  Future<Map<String, dynamic>> endTrip(String tripId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/trip/end");
    final payload = jsonEncode({"tripId": tripId});

    final response = await http
        .post(uri, headers: _headers(token), body: payload)
        .timeout(_timeout);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected trip end response');
  }

  // Get next pending assignment
  Future<RouteAssignment?> getNextPendingAssignment() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/assignments/next-pending");
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(_timeout);
    final data = _decodeResponse(response);

    if (data is Map && data['assignment'] != null) {
      return RouteAssignment.fromJson(
        Map<String, dynamic>.from(data['assignment']),
      );
    }
    return null;
  }

  // Get driver trips
  Future<List<Map<String, dynamic>>> getTrips() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/trips");
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(_timeout);
    final data = _decodeResponse(response);

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  // Get all tickets and reservations for driver
  Future<Map<String, dynamic>> getTicketsAndReservations() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_baseUrl/tickets-reservations");
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(_timeout);
    final data = _decodeResponse(response);

    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected tickets and reservations response');
  }
}
