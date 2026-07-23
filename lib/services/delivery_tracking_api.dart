import 'dart:convert';

import 'package:http/http.dart' as http;

/// REST client for rider location and active-rider tracking.
class DeliveryTrackingApi {
  static const String _baseUrl = 'https://int.foodeez.in/restaurant/api/v1';

  final http.Client _client;

  DeliveryTrackingApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> activeRiders({
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/delivery-tracking/active-riders');
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
    return _normalizeList(decoded);
  }

  Future<void> shareLocation({
    required String accessToken,
    required String partnerId,
    required double latitude,
    required double longitude,
    String? status,
  }) async {
    final uri = Uri.parse('$_baseUrl/delivery-tracking/location');
    final payload = <String, dynamic>{
      'partnerId': partnerId,
      'latitude': latitude,
      'longitude': longitude,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_parseError(res.body));
    }
  }

  List<Map<String, dynamic>> _normalizeList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['data'] ?? decoded['items'] ?? decoded['results'] ?? decoded['activeRiders'] ?? decoded['riders'];
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (raw is Map<String, dynamic>) {
        return [raw];
      }
    }

    return const [];
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
