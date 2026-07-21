import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../services/auth_service.dart';
import '../widgets/foodeez_logo.dart';
import 'otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() => _isLoading = true);
    try {
      await AuthService().sendLoginOtp(email: email);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('TimeoutException after', 'Request timed out after');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isNotEmpty
                ? message
                : 'Unable to send OTP right now. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.read(appControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: Responsive.screenPadding(context, horizontal: 26),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FoodeezLogo(),
                      const SizedBox(height: 20),

                      RichText(
                        text: TextSpan(
                          style: AppText.display(size: 28, letterSpacing: -0.6),
                          children: const [
                            TextSpan(text: "Welcome "),
                            TextSpan(
                              text: "Back",
                              style: TextStyle(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Sign in to your delivery partner account",
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          size: 14,
                          color: AppColors.bodyGrey,
                        ),
                      ),

                      const SizedBox(height: 35),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Email Address",
                          prefixIcon: const Icon(Icons.email_outlined),
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
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your email";
                          }

                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );

                          if (!emailRegex.hasMatch(value.trim())) {
                            return "Enter a valid email";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: _isLoading ? null : _sendOtp,
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
                                  "Send OTP",
                                  style: AppText.body(
                                    size: 16,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: AppText.body(
                            size: 13,
                            color: AppColors.lightGreyText,
                          ),
                          children: [
                            const TextSpan(text: "New delivery partner? "),
                            TextSpan(
                              text: "Sign Up",
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  app.go('signup');
                                },
                            ),
                          ],
                        ),
                      ),
                    ],
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
