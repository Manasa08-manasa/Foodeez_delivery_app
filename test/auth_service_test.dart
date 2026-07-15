import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:foodeez_delivery/services/auth_service.dart';

void main() {
  test('verifyLoginOtp sends email and otp to the verification endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, equals('POST'));
      expect(request.url.toString(), contains('/verify-otp'));
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), {
        'email': 'user@example.com',
        'otp': '123456',
      });
      return http.Response('{"message":"ok"}', 200);
    });

    final service = AuthService(client: client);

    await expectLater(
      service.verifyLoginOtp(email: 'user@example.com', otp: '123456'),
      completes,
    );
  });
}
