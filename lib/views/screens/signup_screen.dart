import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../widgets/common.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Hyderabad');

  String _vehicle = 'Scooter';
  bool _sendingOtp = false;
  bool _creatingAccount = false;
  bool _otpSent = false;

  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static const _vehicles = [
    ('Bicycle', Icons.pedal_bike_outlined),
    ('Scooter', Icons.moped_outlined),
    ('Bike', Icons.two_wheeler_outlined),
    ('Car', Icons.directions_car_outlined),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email")),
      );
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email")),
      );
      return;
    }

    setState(() => _sendingOtp = true);
    try {
      // Verification is sent via the same email-OTP endpoint used at login —
      // there's no separate signup/register endpoint on the backend yet.
      await AuthService().sendLoginOtp(email: email);
      if (!mounted) return;
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP sent successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _submit(AppState app) async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter full name")),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email")),
      );
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email")),
      );
      return;
    }

    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP sent to your email")),
      );
      return;
    }
    if (!_otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please request an OTP first")),
      );
      return;
    }

    if (_passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter password")),
      );
      return;
    }

    if (_confirmPasswordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please confirm password")),
      );
      return;
    }

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _creatingAccount = true);
    try {
      // Confirms the email OTP against the live backend — same endpoint used
      // for login, since there's no dedicated signup/register endpoint yet.
      // A successful response means the email is verified and returns the
      // partner's real profile + access token.
      final authResponse = await AuthService().verifyLoginOtp(email: email, otp: otp);
      if (!mounted) return;

      app.setAuthenticatedUser(
        accessToken: authResponse.accessToken,
        partnerId: authResponse.partner.id,
        partnerName: authResponse.partner.name,
        partnerEmail: authResponse.partner.email,
        partnerStatus: authResponse.partner.status,
        vehicleType: authResponse.partner.vehicleType,
      );

      app.startNewApplication();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _creatingAccount = false);
    }
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
              ScreenHeader(
                title: 'Sign up to deliver',
                onBack: app.back,
              ),

              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 18),
                child: Text(
                  "A few details and we'll get your application to our onboarding team.",
                  style: AppText.body(
                    size: 13,
                    color: AppColors.bodyGrey,
                    height: 1.45,
                  ),
                ),
              ),

              _label('FULL NAME'),
              _field(
                controller: _nameCtrl,
                hint: 'As per your ID proof',
              ),

              const SizedBox(height: 14),

              _label('EMAIL ADDRESS'),
              _field(
                controller: _emailCtrl,
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _sendingOtp ? null : _sendOtp,
                  child: _sendingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : Text(
                          _otpSent ? "Resend OTP" : "Send OTP",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              _label('EMAIL OTP'),
              _field(
                controller: _otpCtrl,
                hint: 'Enter OTP',
              ),

              const SizedBox(height: 14),

              _label('PASSWORD'),
              _field(
                controller: _passwordCtrl,
                hint: 'Enter Password',
                obscure: true,
              ),

              const SizedBox(height: 14),

              _label('CONFIRM PASSWORD'),
              _field(
                controller: _confirmPasswordCtrl,
                hint: 'Confirm Password',
                obscure: true,
              ),

              const SizedBox(height: 14),

              _label('CITY'),
              _field(
                controller: _cityCtrl,
                hint: "City you'll deliver in",
              ),
              
              const SizedBox(height: 14),

              _label('VEHICLE TYPE'),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _vehicles.map((v) {
                  final selected = _vehicle == v.$1;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _vehicle = v.$1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent
                            : Colors.white,
                        border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : AppColors.dividerBorder,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            v.$2,
                            size: 16,
                            color: selected
                                ? Colors.white
                                : AppColors.ink,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            v.$1,
                            style: AppText.body(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.plumTint,
                  border: Border.all(
                    color: AppColors.plumTintBorder,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        "After signing up, you'll upload your driving licence, vehicle RC and insurance for verification.",
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.accent,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: _creatingAccount ? null : () => _submit(app),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _creatingAccount
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : Text(
                          'Create account',
                          style: AppText.body(
                            size: 16,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppText.body(
                      size: 12.5,
                      color: AppColors.lightGreyText,
                    ),
                    children: const [
                      TextSpan(
                        text: 'By continuing you agree to our ',
                      ),
                      TextSpan(
                        text: 'Terms',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 7),
      child: Text(
        text,
        style: AppText.body(
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.bodyGrey,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.dividerBorder,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: AppText.body(
          size: 15,
          weight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppText.body(
            size: 15,
            color: AppColors.lightGreyText,
          ),
        ),
      ),
    );
  }
}