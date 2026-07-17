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
    final normalizedEmail = email.trim().toLowerCase();
    final uri = Uri.parse('$_baseUrl/send-login-otp');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': normalizedEmail}),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }
  }
  
  Future<AuthResponse> verifyLoginOtp({
    required String email,
    required String otp,
    }) async {
      final normalizedEmail = email.trim().toLowerCase();
      final uri = Uri.parse('$_baseUrl/login');

      print("VERIFY REQUEST:");
      print(jsonEncode({
        'email': normalizedEmail,
        'otp': otp,
      }));

      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': normalizedEmail,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 20));

      print("VERIFY OTP STATUS: ${response.statusCode}");
      print("VERIFY OTP RESPONSE: ${response.body}");

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_parseError(response.body));
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response from server');
      }

      return AuthResponse.fromJson(decoded);
    }
  Future<void> sendOtp({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final uri = Uri.parse('$_baseUrl/send-otp');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': normalizedEmail,
      }),
    ).timeout(const Duration(seconds: 20));

    print("SEND OTP STATUS: ${response.statusCode}");
    print("SEND OTP RESPONSE: ${response.body}");

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }
  }
  
  Future<void> verifyOtp({
    required String email,
    required String otp,
    }) async {
      final normalizedEmail = email.trim().toLowerCase();
      final uri = Uri.parse('$_baseUrl/verify-otp');
      
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': normalizedEmail,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 20));

      print("VERIFY OTP STATUS: ${response.statusCode}");
      print("VERIFY OTP RESPONSE: ${response.body}");

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_parseError(response.body));
      }
    }

  Future<String> reverseGeocode({required double lat, required double lon}) async {
    final details = await reverseGeocodeDetailed(lat: lat, lon: lon);
    return details['address'] ?? '';
  }

  /// Same nominatim reverse-geocode call the web app makes from the
  /// signup "Location" step, but also pulls out city/state so the form
  /// fields can be auto-filled instead of just a free-text address.
  Future<Map<String, String>> reverseGeocodeDetailed({required double lat, required double lon}) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon');
    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const {};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final addr = decoded['address'] as Map<String, dynamic>? ?? const {};
        final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '').toString();
        final state = (addr['state'] ?? '').toString();
        return {
          'address': decoded['display_name']?.toString() ?? '',
          'city': city,
          'state': state,
        };
      }
    } catch (_) {}

    return const {};
  }
  
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String phone,
    required String city,
    required String state,
    required String vehicleType,
    required String vehicleNumber,
    required String licenseNumber,
    required String otp,
    String? address,
    double? latitude,
    double? longitude,
    // Login on the web is OTP-only (no password step in the signup
    // stepper), so this stays optional and is only sent if the caller
    // explicitly provides one.
    String? password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final uri = Uri.parse('$_baseUrl/signup');

    final body = {
      'name': name,
      'email': normalizedEmail,
      'phone': phone,
      'city': city,
      'state': state,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
      'otp': otp,
      'address': address ?? '',
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (password != null && password.isNotEmpty) 'password': password,
    };

    print("SIGNUP REQUEST:");
    print(jsonEncode(body));

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    print("SIGNUP STATUS: ${response.statusCode}");
    print("SIGNUP RESPONSE: ${response.body}");

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response from server');
    }

    return AuthResponse.fromJson(decoded);
  }

  Future<void> uploadSignupDocuments({
    required String accessToken,
    required String partnerId,
    required String documentType,
    required String documentNumber,
    required String fileName,
  }) async {
    final uri = Uri.parse('$_baseUrl/signup/documents');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'partnerId': partnerId,
        'documentType': documentType,
        'documentNumber': documentNumber,
        'fileName': fileName,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }
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
