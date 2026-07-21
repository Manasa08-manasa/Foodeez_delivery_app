import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../services/auth_service.dart';
import '../widgets/common.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _verifyCompleted = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().sendLoginOtp(email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully')),
        );
        setState(() => _otpSent = true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to resend OTP right now')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verifyCompleted || _isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final otp = _otpCtrl.text.trim();
      final authResponse = await AuthService().verifyLoginOtp(
        email: widget.email,
        otp: otp,
      );
      if (!mounted) return;

      _verifyCompleted = true;
      ref
          .read(appControllerProvider)
          .setAuthenticatedUser(
            accessToken: authResponse.accessToken,
            partnerId: authResponse.partner.id,
            partnerName: authResponse.partner.name,
            partnerEmail: authResponse.partner.email,
            partnerStatus: authResponse.partner.status,
            vehicleType: authResponse.partner.vehicleType,
          );
      ref.read(appControllerProvider).toHome();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _goBackToLogin() {
    if (_verifyCompleted || _isLoading) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading && !_verifyCompleted,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: Responsive.screenPadding(context, horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        BackButtonChip(onTap: _goBackToLogin),
                        const SizedBox(width: 12),
                        Text('Verify OTP', style: AppText.display(size: 20)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter the 6-digit code sent to ${widget.email}',
                    style: AppText.body(size: 14, color: AppColors.bodyGrey),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _otpCtrl,
                    enabled: !_verifyCompleted && !_isLoading,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: 'Enter OTP',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Please enter OTP';
                      if (value.trim().length < 4)
                        return 'OTP must be at least 4 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _verifyCompleted)
                          ? null
                          : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Verify',
                              style: AppText.body(
                                size: 16,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: (_isLoading || _verifyCompleted)
                          ? null
                          : _resendOtp,
                      child: Text(
                        'Resend OTP',
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
