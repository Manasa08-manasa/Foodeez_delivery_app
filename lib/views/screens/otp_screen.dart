import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
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
  final _otpFocus = FocusNode();
  bool _isLoading = false;
  bool _verifyCompleted = false;

  @override
  void initState() {
    super.initState();
    _otpCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  int get _otpLength => _otpCtrl.text.trim().length;

  bool get _canVerify => _otpLength == 6 && !_isLoading && !_verifyCompleted;

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().sendLoginOtp(email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully')),
        );
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
    if (!_canVerify) return;
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
      ref.read(appControllerProvider).setAuthenticatedUser(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleBackButton(onTap: _goBackToLogin),
                      _SecureBadge(),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Verify OTP',
                    style: AppText.display(size: 34, weight: FontWeight.w800, color: AppColors.accent, letterSpacing: -0.8),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Enter the 6-digit code sent to',
                    textAlign: TextAlign.center,
                    style: AppText.body(size: 14.5, color: AppColors.bodyGrey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: AppText.body(size: 15, weight: FontWeight.w800, color: AppColors.ink),
                  ),
                  const SizedBox(height: 28),
                  _OtpInputBox(
                    controller: _otpCtrl,
                    focusNode: _otpFocus,
                    enabled: !_verifyCompleted && !_isLoading,
                    onTap: () => _otpFocus.requestFocus(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _otpLength / 6,
                            minHeight: 3,
                            backgroundColor: AppColors.dividerBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$_otpLength/6',
                        style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.bodyGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canVerify ? _verifyOtp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canVerify ? AppColors.accent : const Color(0xFF9BA8B5),
                        disabledBackgroundColor: const Color(0xFF9BA8B5),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Text('Verify', style: AppText.body(size: 16, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton.icon(
                      onPressed: (_isLoading || _verifyCompleted) ? null : _resendOtp,
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.accent),
                      label: Text(
                        'Resend OTP',
                        style: AppText.body(size: 14.5, weight: FontWeight.w800, color: AppColors.accent),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppText.body(size: 12.5, color: AppColors.lightGreyText, height: 1.55),
                        children: [
                          const TextSpan(text: "Didn't get the email? Check your spam folder or make sure "),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.midGrey),
                          ),
                          const TextSpan(text: ' is correct.'),
                        ],
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

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, size: 20, color: AppColors.midGrey),
      ),
    );
  }
}

class _SecureBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 14, color: AppColors.bodyGrey.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text('Secure verification', style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
        ],
      ),
    );
  }
}

class _OtpInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onTap;

  const _OtpInputBox({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otp = controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.plumTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_outline, size: 18, color: AppColors.accent),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) {
                          final filled = i < otp.length;
                          return Container(
                            width: filled ? 10 : 8,
                            height: filled ? 10 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? AppColors.accent : AppColors.lightGreyText.withValues(alpha: 0.55),
                            ),
                          );
                        }),
                      ),
                      TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: enabled,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        obscureText: true,
                        obscuringCharacter: '•',
                        showCursor: false,
                        enableSuggestions: false,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter OTP';
                          if (value.trim().length != 6) return 'Enter all 6 digits';
                          return null;
                        },
                        style: const TextStyle(color: Colors.transparent, fontSize: 1, height: 0.01),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isCollapsed: true,
                          errorStyle: TextStyle(height: 0, fontSize: 0),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
