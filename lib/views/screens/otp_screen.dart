import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _otpSent = false;

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final otp = _otpCtrl.text.trim();
      final authResponse = await AuthService().verifyLoginOtp(
        email: widget.email,
        otp: otp,
      );
      if (!mounted) return;
      ref.read(appControllerProvider).setAuthenticatedUser(
        accessToken: authResponse.accessToken,
        partnerId: authResponse.partner.id,
        partnerName: authResponse.partner.name,
        partnerEmail: authResponse.partner.email,
        partnerStatus: authResponse.partner.status,
        vehicleType: authResponse.partner.vehicleType,
      );
      ref.read(appControllerProvider).toHome();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.read(appControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.accent),
          onPressed: app.back,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verify OTP', style: AppText.display(size: 28, letterSpacing: -0.5)),
                const SizedBox(height: 10),
                Text('Enter the 6-digit code sent to ${widget.email}', style: AppText.body(size: 14, color: AppColors.bodyGrey)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter OTP',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter OTP';
                    if (value.trim().length < 4) return 'OTP must be at least 4 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                        : Text('Verify', style: AppText.body(size: 16, weight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: Text(_otpSent ? 'Resend OTP' : 'Resend OTP', style: AppText.body(size: 14, weight: FontWeight.w700, color: AppColors.accent)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
