import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Hyderabad');
  String _vehicle = 'Scooter';

  static const _vehicles = [
    ('Bicycle', Icons.pedal_bike_outlined),
    ('Scooter', Icons.moped_outlined),
    ('Bike', Icons.two_wheeler_outlined),
    ('Car', Icons.directions_car_outlined),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.read(appControllerProvider);
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(title: 'Sign up to deliver', onBack: app.back),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 18),
                child: Text('A few details and we\'ll get your application to our onboarding team.', style: AppText.body(size: 13, color: AppColors.bodyGrey, height: 1.45)),
              ),
              _label('FULL NAME'),
              _field(controller: _nameCtrl, hint: 'As per your ID proof'),
              const SizedBox(height: 14),
              _label('PHONE NUMBER'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.dividerBorder, width: 1.5)),
                child: Row(
                  children: [
                    Text('+91', style: AppText.body(size: 15, weight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Container(width: 1, height: 20, color: AppColors.dividerBorder),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: AppText.body(size: 15, weight: FontWeight.w600),
                        decoration: InputDecoration(border: InputBorder.none, hintText: 'Mobile number', hintStyle: AppText.body(size: 15, color: AppColors.lightGreyText)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _label('CITY'),
              _field(controller: _cityCtrl, hint: 'City you\'ll deliver in'),
              const SizedBox(height: 14),
              _label('VEHICLE TYPE'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _vehicles.map((v) {
                  final selected = _vehicle == v.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _vehicle = v.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: selected ? AppColors.accent : Colors.white, border: Border.all(color: selected ? AppColors.accent : AppColors.dividerBorder, width: 1.5), borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(v.$2, size: 16, color: selected ? Colors.white : AppColors.ink),
                        const SizedBox(width: 8),
                        Text(v.$1, style: AppText.body(size: 13.5, weight: FontWeight.w700, color: selected ? Colors.white : AppColors.ink)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(color: AppColors.plumTint, border: Border.all(color: AppColors.plumTintBorder, width: 1.5), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 18, color: AppColors.accent),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text('After signing up, you\'ll upload your driving licence, vehicle RC and insurance for verification.', style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.accent, height: 1.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: app.startNewApplication,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))]),
                  alignment: Alignment.center,
                  child: Text('Create account', style: AppText.body(size: 16, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: RichText(
                  text: TextSpan(style: AppText.body(size: 12.5, color: AppColors.lightGreyText), children: const [
                    TextSpan(text: 'By continuing you agree to our '),
                    TextSpan(text: 'Terms', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                    TextSpan(text: ' & '),
                    TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 7),
        child: Text(text, style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 0.6)),
      );

  Widget _field({required TextEditingController controller, required String hint}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.dividerBorder, width: 1.5)),
        child: TextField(
          controller: controller,
          style: AppText.body(size: 15, weight: FontWeight.w600),
          decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: AppText.body(size: 15, color: AppColors.lightGreyText)),
        ),
      );
}
