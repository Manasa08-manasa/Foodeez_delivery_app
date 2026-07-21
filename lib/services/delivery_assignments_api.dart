import 'dart:convert';

import 'package:http/http.dart' as http;

/// REST client for delivery assignment actions.
///
/// Endpoints are based on your downloaded frontend:
/// - POST   /delivery-assignments/:id/claim
/// - PATCH  /delivery-assignments/:id/reject
/// - PATCH  /delivery-assignments/:id/status
class DeliveryAssignmentsApi {
  // Matches `AuthService._baseUrl` in this project.
  static const String _baseUrl = 'https://int.foodeez.in/restaurant/api/v1';

  final http.Client _client;

  DeliveryAssignmentsApi({http.Client? client}) : _client = client ?? http.Client();

  Future<void> claim({
    required String accessToken,
    required String assignmentId,
    required String partnerId,
  }) async {
    final uri = Uri.parse('$_baseUrl/delivery-assignments/$assignmentId/claim');
    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'partnerId': partnerId}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_parseError(res.body));
    }
  }

  Future<void> reject({
    required String accessToken,
    required String assignmentId,
    String? partnerId,
    String? reason,
  }) async {
    final uri = Uri.parse('$_baseUrl/delivery-assignments/$assignmentId/reject');

    final payload = <String, dynamic>{
      if (partnerId != null) 'partnerId': partnerId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };

    final res = await _client.patch(
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

  /// status must be a backend DeliveryStatus string, e.g.:
  /// `PICKED_UP`, `ON_THE_WAY`, `ARRIVED`, `DELIVERED`, etc.
  Future<void> updateStatus({
    required String accessToken,
    required String assignmentId,
    required String status,
    String? cancellationReason,
    double? partnerLatitude,
    double? partnerLongitude,
  }) async {
    final uri = Uri.parse('$_baseUrl/delivery-assignments/$assignmentId/status');

    final payload = <String, dynamic>{
      'status': status,
      if (cancellationReason != null && cancellationReason.isNotEmpty) 'cancellationReason': cancellationReason,
      if (partnerLatitude != null) 'partnerLatitude': partnerLatitude,
      if (partnerLongitude != null) 'partnerLongitude': partnerLongitude,
    };

    final res = await _client.patch(
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

  /// Fetch assignments for a delivery partner.
  ///
  /// Backend: `GET /delivery-assignments/partner/:partnerId?page=&limit=`
  Future<List<Map<String, dynamic>>> byPartner({
    required String accessToken,
    required String partnerId,
    int page = 1,
    int limit = 50,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/delivery-assignments/partner/$partnerId?page=$page&limit=$limit',
    );

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
    if (decoded is List) {
      return decoded.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    if (decoded is Map<String, dynamic>) {
      final raw = decoded['data'] ?? decoded['items'] ?? decoded['results'] ?? decoded['assignments'];
      if (raw is List) {
        return raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
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

