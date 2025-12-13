import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waygo/services/api_service.dart';

class AdminService {
  AdminService();

  static const String _apiBase = "http://10.0.2.2:5000/api";
  static const String _adminBase = "$_apiBase/admin";
  static const Duration _timeout = Duration(seconds: 12);

  final AuthService _authService = AuthService();

  Future<String?> _getToken() => _authService.getToken();

  Map<String, String> _authHeaders(String token) => {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

  dynamic _decode(http.Response response) {
    final body =
        response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body is Map && body['error'] != null
        ? body['error']
        : 'Request failed (${response.statusCode})';
    throw Exception(message);
  }

  Future<Map<String, dynamic>> getBusDriverStats() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/buses-drivers/stats");
    final response =
        await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
    final data = _decode(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected stats response');
  }

  Future<List<dynamic>> getRoutes() async {
    final uri = Uri.parse("$_apiBase/routes");
    final headers = {
      "Content-Type": "application/json",
    };
    final token = await _getToken();
    if (token != null) headers["Authorization"] = "Bearer $token";

    final response = await http.get(uri, headers: headers).timeout(_timeout);
    final data = _decode(response);
    if (data is List) return data;
    throw Exception('Unexpected routes response');
  }

  Future<Map<String, dynamic>> createAssignment({
    required String driverId,
    required String routeId,
    required String scheduledDate,
    required String scheduledTime,
    String? busId,
    String? depotId,
    String? notes,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/assignments");
    final payload = jsonEncode({
      "driverId": driverId,
      "routeId": routeId,
      "scheduledDate": scheduledDate,
      "scheduledTime": scheduledTime,
      if (busId != null && busId.isNotEmpty) "busId": busId,
      if (depotId != null && depotId.isNotEmpty) "depotId": depotId,
      if (notes != null && notes.isNotEmpty) "notes": notes,
    });

    final response = await http
        .post(uri, headers: _authHeaders(token), body: payload)
        .timeout(_timeout);

    final data = _decode(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected assignment response');
  }

  Future<Map<String, dynamic>> createBus({
    required String busNumber,
    required String busName,
    int? totalSeats,
    String? busType,
    String? depotId,
    String conditionStatus = "workable",
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_apiBase/bus/admin");
    final payload = jsonEncode({
      "busNumber": busNumber,
      "busName": busName,
      if (totalSeats != null) "totalSeats": totalSeats,
      if (busType != null && busType.isNotEmpty) "busType": busType,
      if (depotId != null && depotId.isNotEmpty) "depotId": depotId,
      "conditionStatus": conditionStatus,
    });

    final response = await http
        .post(uri, headers: _authHeaders(token), body: payload)
        .timeout(_timeout);

    final data = _decode(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected bus create response');
  }

  Future<Map<String, dynamic>> updateBusCondition({
    required String busId,
    required String conditionStatus,
    String? depotId,
    String? notes,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/buses/$busId/status");
    final payload = <String, dynamic>{
      "conditionStatus": conditionStatus,
      if (depotId != null) "depotId": depotId,
      if (notes != null) "notes": notes,
    };

    final response = await http
        .patch(uri, headers: _authHeaders(token), body: jsonEncode(payload))
        .timeout(_timeout);

    final data = _decode(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected bus status response');
  }

  Future<Map<String, dynamic>> updateDriverDutyStatus({
    required String driverId,
    required String dutyStatus,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/drivers/$driverId/duty-status");
    final payload = jsonEncode({"dutyStatus": dutyStatus});

    final response = await http
        .put(uri, headers: _authHeaders(token), body: payload)
        .timeout(_timeout);

    final data = _decode(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected driver status response');
  }

  Future<void> resetDriverAssignment(String driverId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/drivers/$driverId/reset-assignment");
    final response =
        await http.put(uri, headers: _authHeaders(token)).timeout(_timeout);
    _decode(response);
  }

  // Delete assignment (this will release the bus if it's assigned)
  Future<void> deleteAssignment(String assignmentId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/assignments/$assignmentId");
    final response =
        await http.delete(uri, headers: _authHeaders(token)).timeout(_timeout);
    _decode(response);
  }

  Future<List<dynamic>> getDepots() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/depots");
    final response =
        await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
    final data = _decode(response);
    if (data is List) return data;
    throw Exception('Unexpected depots response');
  }

  Future<Map<String, dynamic>> getPricingStats() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/pricing/stats");
    final response =
        await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
    final data = _decode(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected pricing stats response');
  }

  // Get all users with optional filters
  Future<List<dynamic>> getAllUsers({
    String? userType,
    bool? isActive,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/users").replace(queryParameters: {
      if (userType != null && userType != 'All Roles')
        'userType': userType.toLowerCase(),
      if (isActive != null) 'isActive': isActive.toString(),
    });

    final response =
        await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
    final data = _decode(response);
    if (data is List) return data;
    throw Exception('Unexpected users response');
  }

  // Update user status (Active/Suspended)
  Future<Map<String, dynamic>> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/users/$userId/status");
    final payload = jsonEncode({"isActive": isActive});

    final response = await http
        .put(uri, headers: _authHeaders(token), body: payload)
        .timeout(_timeout);

    final data = _decode(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected update user status response');
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_adminBase/users/$userId");
    final response =
        await http.delete(uri, headers: _authHeaders(token)).timeout(_timeout);
    _decode(response);
  }

  // Update route price
  Future<Map<String, dynamic>> updateRoutePrice({
    required String routeId,
    double? price,
    double? priceDeluxe,
    double? priceLuxury,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse("$_apiBase/routes/admin/$routeId");
    final payload = <String, dynamic>{};
    if (price != null) payload['price'] = price;
    if (priceDeluxe != null) payload['priceDeluxe'] = priceDeluxe;
    if (priceLuxury != null) payload['priceLuxury'] = priceLuxury;

    final response = await http
        .put(uri, headers: _authHeaders(token), body: jsonEncode(payload))
        .timeout(_timeout);

    final data = _decode(response);
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected update route price response');
  }
}

