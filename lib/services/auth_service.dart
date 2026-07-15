import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthResponse {
  const AuthResponse({required this.accessToken, required this.partner});

  final String accessToken;
  final PartnerProfile partner;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final partnerJson = json['partner'] as Map<String, dynamic>? ?? const {};
    return AuthResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      partner: PartnerProfile.fromJson(partnerJson),
    );
  }
}

class PartnerProfile {
  const PartnerProfile({required this.id, required this.name, required this.email, required this.status, required this.vehicleType});

  final String id;
  final String name;
  final String email;
  final String status;
  final String vehicleType;

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
    );
  }
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://int.foodeez.in/restaurant/api/v1/auth/partner';
  final http.Client _client;

  Future<void> sendLoginOtp({required String email}) async {
    final uri = Uri.parse('$_baseUrl/send-login-otp');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }
  }

  Future<AuthResponse> verifyLoginOtp({required String email, required String otp}) async {
    final uri = Uri.parse('$_baseUrl/login');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response from server');
    }

    return AuthResponse.fromJson(decoded);
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}

    return 'Unable to complete the request. Please try again.';
  }
}
