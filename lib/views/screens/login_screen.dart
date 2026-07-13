import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 152, height: 152, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.gold.withValues(alpha: 0.28), Colors.transparent]))),
                        Image.asset('assets/images/foodeez-mark.png', width: 104),
                      ],
                    ),
                    const SizedBox(height: 18),
                    RichText(
                      text: TextSpan(style: AppText.display(size: 28, letterSpacing: -0.6), children: const [
                        TextSpan(text: 'Foodeez '),
                        TextSpan(text: 'Rider', style: TextStyle(color: AppColors.accent)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 256,
                      child: Text('Deliver on your schedule. Go online, accept orders, earn more with every trip.', textAlign: TextAlign.center, style: AppText.body(size: 14, color: AppColors.bodyGrey)),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.dividerBorder, width: 1.5)),
                    child: Row(
                      children: [
                        Text('+91', style: AppText.body(size: 15, weight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        Container(width: 1, height: 20, color: AppColors.dividerBorder),
                        const SizedBox(width: 10),
                        Text('Registered rider number', style: AppText.body(size: 15, color: AppColors.lightGreyText)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => app.tab('home'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))]),
                      alignment: Alignment.center,
                      child: Text('Log in & go online', style: AppText.body(size: 16, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(style: AppText.body(size: 12.5, color: AppColors.lightGreyText), children: [
                      const TextSpan(text: 'New rider? '),
                      TextSpan(
                        text: 'Sign up to deliver',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                        recognizer: TapGestureRecognizer()..onTap = () => app.go('signup'),
                      ),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
