import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodeez_delivery/views/screens/otp_screen.dart';

void main() {
  testWidgets('otp verification screen renders email and otp actions', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OtpVerificationScreen(email: 'test@example.com')),
      ),
    );

    expect(find.text('Verify OTP'), findsOneWidget);
    expect(find.text('Resend OTP'), findsOneWidget);
  });
}
