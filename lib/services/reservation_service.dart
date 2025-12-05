import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waygo/services/api_service.dart';

class ReservationService {
  static const String baseUrl = "http://10.0.2.2:5000/api";
  static const Duration _timeout = Duration(seconds: 10);

  Future<String?> _getToken() async {
    final token = await AuthService().getToken();
    print('🔐 Token retrieved: ${token != null ? "EXISTS" : "NULL"}');
    if (token != null) {
      print('🔐 Token length: ${token.length}');
      print(
        '🔐 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
      );
    }
    return token;
  }

  Map<String, String> _defaultHeaders([String? token]) {
    final headers = <String, String>{"Content-Type": "application/json"};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
      print('🔐 Authorization header set: Bearer ${token.substring(0, 20)}...');
    } else {
      print('⚠️ No token provided to headers');
    }
    return headers;
  }

  // Central response handler - decodes JSON or throws with a meaningful message
  dynamic _handleResponse(http.Response response) {
    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    try {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        final errorMsg = (body is Map && body['error'] != null)
            ? body['error']
            : 'Request failed with status ${response.statusCode}';
        print('❌ Server Error: $errorMsg');
        throw Exception(errorMsg);
      }
    } on FormatException {
      throw Exception('Invalid JSON received (status ${response.statusCode})');
    }
  }

  // Search routes
  Future<List<Map<String, dynamic>>> searchRoutes({
    required String start,
    required String destination,
    required String date,
  }) async {
    try {
      print('🔵 Searching routes: $start → $destination on $date');
      final uri = Uri.parse("$baseUrl/routes/search").replace(
        queryParameters: {
          'start': start,
          'destination': destination,
          'date': date,
        },
      );

      final response = await http
          .get(uri, headers: _defaultHeaders())
          .timeout(_timeout);
      final data = _handleResponse(response);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    } catch (e) {
      print('❌ Search routes error: $e');
      rethrow;
    }
  }

  // Get booked seats for a route on a date
  Future<List<int>> getBookedSeats(String routeId, String date) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse(
        "$baseUrl/reservations/booked-seats",
      ).replace(queryParameters: {'routeId': routeId, 'date': date});

      final response = await http
          .get(uri, headers: _defaultHeaders(token))
          .timeout(_timeout);
      final data = _handleResponse(response);
      if (data is Map && data['bookedSeats'] is List) {
        return List<int>.from(data['bookedSeats']);
      }
      return [];
    } catch (e) {
      print('❌ Get booked seats error: $e');
      return [];
    }
  }

  // Create reservation (without payment)
  Future<Map<String, dynamic>> createReservation({
    required String routeId,
    required List<int> seats,
    required String date,
  }) async {
    try {
      print('═══════════════════════════════════════');
      print('🔵 CREATE RESERVATION DEBUG');
      print('═══════════════════════════════════════');

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ CRITICAL: Token is null or empty!');
        throw Exception('Not authenticated');
      }

      print('✅ Token obtained successfully');
      print(
        '🔵 Creating reservation: route=$routeId, seats=$seats, date=$date',
      );

      final uri = Uri.parse("$baseUrl/reservations");
      print('📍 URL: $uri');

      final body = jsonEncode({
        "routeId": routeId,
        "seats": seats,
        "date": date,
      });
      print('📦 Body: $body');

      final headers = _defaultHeaders(token);
      print('📋 Headers: $headers');

      print('📤 Sending POST request...');
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);

      final data = _handleResponse(response);
      if (data is Map<String, dynamic>) {
        print('✅ Reservation created successfully');
        print('═══════════════════════════════════════');
        return data;
      }
      throw Exception('Unexpected response shape when creating reservation');
    } catch (e) {
      print('❌ Create reservation error: $e');
      print('═══════════════════════════════════════');
      rethrow;
    }
  }

  // Confirm reservation (Stripe)
  Future<Map<String, dynamic>> confirmReservation({
    required String reservationId,
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      print('═══════════════════════════════════════');
      print('🔵 CONFIRM RESERVATION DEBUG');
      print('═══════════════════════════════════════');

      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('✅ Token obtained successfully');
      print('🔵 Confirming reservation: $reservationId with $paymentMethod');
      print('💰 Amount: $amount');

      final uri = Uri.parse("$baseUrl/reservations/confirm");
      print('📍 URL: $uri');

      final bodyData = {
        "reservationId": reservationId,
        "paymentMethod": paymentMethod,
        "amount": amount,
      };
      final body = jsonEncode(bodyData);
      print('📦 Body: $body');

      final headers = _defaultHeaders(token);
      print('📋 Headers: $headers');

      print('📤 Sending POST request...');
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);

      final data = _handleResponse(response);
      if (data is Map<String, dynamic>) {
        print('✅ Reservation confirmed successfully');
        print('═══════════════════════════════════════');
        return data;
      }
      throw Exception('Unexpected response shape on confirmReservation');
    } catch (e) {
      print('❌ Confirm reservation error: $e');
      print('═══════════════════════════════════════');
      rethrow;
    }
  }

  // Confirm reservation with card details (Legacy)
  Future<Map<String, dynamic>> confirmReservationWithCard({
    required String reservationId,
    required Map<String, dynamic> cardDetails,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('🔵 Confirming reservation with card: $reservationId');
      final uri = Uri.parse("$baseUrl/reservations/confirm");
      final body = jsonEncode({"reservationId": reservationId, "cardDetails": cardDetails});

      final response = await http.post(uri, headers: _defaultHeaders(token), body: body).timeout(_timeout);
      final data = _handleResponse(response);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Unexpected response shape on confirmReservationWithCard');
    } catch (e) {
      print('❌ Confirm reservation error: $e');
      rethrow;
    }
  }

  // Get user reservations
  Future<List<Map<String, dynamic>>> getUserReservations() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse("$baseUrl/reservations/my-reservations");
      final response = await http.get(uri, headers: _defaultHeaders(token)).timeout(_timeout);
      final data = _handleResponse(response);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    } catch (e) {
      print('❌ Get user reservations error: $e');
      rethrow;
    }
  }

  // Get reservation by ID
  Future<Map<String, dynamic>> getReservationById(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse("$baseUrl/reservations/$id");
      final response = await http.get(uri, headers: _defaultHeaders(token)).timeout(_timeout);
      final data = _handleResponse(response);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Unexpected response shape when fetching reservation');
    } catch (e) {
      print('❌ Get reservation by ID error: $e');
      rethrow;
    }
  }

  // Validate ticket (driver)
  Future<Map<String, dynamic>> validateTicket(String ticketId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse("$baseUrl/reservations/validate");
      final response = await http.post(uri, headers: _defaultHeaders(token), body: jsonEncode({"ticketId": ticketId})).timeout(_timeout);
      final data = _handleResponse(response);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Unexpected response shape when validating ticket');
    } catch (e) {
      print('❌ Validate ticket error: $e');
      rethrow;
    }
  }

  // Get trip passengers (driver)
  Future<List<Map<String, dynamic>>> getTripPassengers(String tripId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse("$baseUrl/driver/trip/$tripId/passengers");
      final response = await http.get(uri, headers: _defaultHeaders(token)).timeout(_timeout);
      final data = _handleResponse(response);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    } catch (e) {
      print('❌ Get trip passengers error: $e');
      rethrow;
    }
  }

  // Mark passenger status (driver)
  Future<void> markPassengerStatus({
    required String reservationId,
    required String status, // "boarded" or "absent"
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse("$baseUrl/driver/passenger/status");
      final response = await http.post(uri, headers: _defaultHeaders(token), body: jsonEncode({
        "reservationId": reservationId,
        "status": status,
      })).timeout(_timeout);

      _handleResponse(response); // will throw if non-2xx
    } catch (e) {
      print('❌ Mark passenger status error: $e');
      rethrow;
    }
  }

  // Get route prices by type (for ticket prices page)
  Future<List<Map<String, dynamic>>> getRoutePricesByType() async {
    try {
      print('🔵 Fetching route prices by type');
      final uri = Uri.parse("$baseUrl/routes/prices");

      final response = await http.get(uri, headers: _defaultHeaders()).timeout(_timeout);
      final data = _handleResponse(response);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    } catch (e) {
      print('❌ Get route prices error: $e');
      rethrow;
    }
  }

  // Get all routes with full details (for schedule page)
  Future<List<Map<String, dynamic>>> getAllRoutesWithDetails() async {
    try {
      print('🔵 Fetching all routes with details');
      final uri = Uri.parse("$baseUrl/routes");

      final response = await http.get(uri, headers: _defaultHeaders()).timeout(_timeout);
      final data = _handleResponse(response);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return [];
    } catch (e) {
      print('❌ Get all routes error: $e');
      rethrow;
    }
  }
}