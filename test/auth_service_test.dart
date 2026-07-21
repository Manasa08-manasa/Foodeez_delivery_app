import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:foodeez_delivery/services/auth_service.dart';

void main() {
  test('sendLoginOtp posts to the partner send-login-otp endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, equals('POST'));
      expect(request.url.toString(), contains('/send-login-otp'));
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), {'email': 'user@example.com'});
      return http.Response('{"message":"ok"}', 200);
    });

    final service = AuthService(client: client);

    await expectLater(service.sendLoginOtp(email: 'user@example.com'), completes);
  });

  test('verifyLoginOtp posts to the partner login endpoint with email and otp', () async {
    final client = MockClient((request) async {
      expect(request.method, equals('POST'));
      expect(request.url.toString(), contains('/login'));
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), {
        'email': 'user@example.com',
        'otp': '123456',
      });
      return http.Response('{"accessToken":"token","partner":{"id":"1","name":"Test","email":"user@example.com","status":"pendingReview","vehicleType":"Scooter"}}', 200);
    });

    final service = AuthService(client: client);

    final response = await service.verifyLoginOtp(email: 'user@example.com', otp: '123456');

    expect(response.accessToken, equals('token'));
    expect(response.partner.name, equals('Test'));
  });

  test('signup posts to the partner signup endpoint with the expected payload', () async {
    final client = MockClient((request) async {
      expect(request.method, equals('POST'));
      expect(request.url.toString(), contains('/signup'));
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), {
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'phone': '9876543210',
        'password': 'secret123',
        'city': 'Hyderabad',
        'state': 'Telangana',
        'vehicleType': 'Scooter',
        'vehicleNumber': 'TS09AB1234',
        'licenseNumber': 'DL12345678',
        'otp': '123456',
        'address': 'Some address',
      });
      return http.Response('{"accessToken":"token","partner":{"id":"2","name":"Jane Doe","email":"jane@example.com","status":"pendingReview","vehicleType":"Scooter"}}', 200);
    });

    final service = AuthService(client: client);

    final response = await service.signup(
      name: 'Jane Doe',
      email: 'jane@example.com',
      phone: '9876543210',
      password: 'secret123',
      city: 'Hyderabad',
      state: 'Telangana',
      vehicleType: 'Scooter',
      vehicleNumber: 'TS09AB1234',
      licenseNumber: 'DL12345678',
      otp: '123456',
      address: 'Some address',
    );

    expect(response.partner.email, equals('jane@example.com'));
  });
}
