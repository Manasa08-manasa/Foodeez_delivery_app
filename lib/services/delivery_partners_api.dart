import 'dart:convert';

import 'package:http/http.dart' as http;

/// REST client for delivery partners actions (online/offline).
class DeliveryPartnersApi {
  static const String _baseUrl = 'https://int.foodeez.in/restaurant/api/v1';

  final http.Client _client;

  DeliveryPartnersApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getEarnings({
    required String accessToken,
    required String partnerId,
  }) async {
    final uri = Uri.parse('$_baseUrl/delivery-partners/$partnerId/earnings');
    final res = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_parseError(res.body));
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }

  Future<void> toggleOnline({
    required String accessToken,
    required String partnerId,
    required bool isOnline,
  }) async {
    final uri = Uri.parse('$_baseUrl/delivery-partners/$partnerId/online-status');
    final res = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'isOnline': isOnline}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_parseError(res.body));
    }
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return body.isNotEmpty ? body : 'Request failed';
  }
}

