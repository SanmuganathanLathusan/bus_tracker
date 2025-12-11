import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:waygo/services/api_service.dart';

class NotificationService {
  static const String _baseUrl = "http://10.0.2.2:5000/api/notifications";
  static const Duration _timeout = Duration(seconds: 10);

  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> fetchNotifications({
    String? type,
    bool? unreadOnly,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final query = <String, String>{};
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }
    if (unreadOnly == true) {
      query['isRead'] = 'false'; // only unread items
    }

    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: query.isEmpty ? null : query);

    print('📬 Fetching notifications: $uri');

    final response = await http
        .get(
          uri,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .timeout(_timeout);

    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) {
      final count = (data['notifications'] as List?)?.length ?? 0;
      final unread = data['unreadCount'] ?? 0;
      print('✅ Loaded $count notifications ($unread unread)');
      return data;
    }
    throw Exception('Unexpected notification payload');
  }

  Future<void> markAsRead(String notificationId) async {
    await _authorizedRequest(
      method: _HttpMethod.put,
      path: "/$notificationId/read",
    );
  }

  Future<void> markAllAsRead() async {
    await _authorizedRequest(method: _HttpMethod.put, path: "/read-all");
  }

  Future<void> deleteNotification(String notificationId) async {
    await _authorizedRequest(
      method: _HttpMethod.delete,
      path: "/$notificationId",
    );
  }

  Future<dynamic> _authorizedRequest({
    required _HttpMethod method,
    required String path,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse("$_baseUrl$path");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    http.Response response;
    switch (method) {
      case _HttpMethod.get:
        response = await http.get(uri, headers: headers).timeout(_timeout);
        break;
      case _HttpMethod.put:
        response = await http.put(uri, headers: headers).timeout(_timeout);
        break;
      case _HttpMethod.delete:
        response = await http.delete(uri, headers: headers).timeout(_timeout);
        break;
    }

    return _decodeResponse(response, allowEmpty: true);
  }

  dynamic _decodeResponse(http.Response response, {bool allowEmpty = false}) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (allowEmpty && response.statusCode == 204) {
      return null;
    }

    final message = body is Map && body['error'] != null
        ? body['error']
        : 'Request failed (${response.statusCode})';
    throw Exception(message);
  }
}

enum _HttpMethod { get, put, delete }
