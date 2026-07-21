import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../services/auth_service.dart';
import '../widgets/common.dart';

/// Mirrors https://int.foodeez.in/delivery/auth/signup's own 5-step
/// stepper: Email -> OTP -> Location -> Vehicle -> Documents.
/// Documents is handled the same way the web app's "pending review" state
/// works today in this app: right after account creation the rider is
/// dropped onto the document-upload screen (see AppState.startNewApplication
/// and ProfileScreen), so it isn't a form step in here.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  String _address = '';
  double? _latitude;
  double? _longitude;

  final _vehicleNumberCtrl = TextEditingController();
  final _licenseNumberCtrl = TextEditingController();

  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _locating = false;
  bool _creatingAccount = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  int _step = 0;

  static const int _stepEmail = 0;
  static const int _stepOtp = 1;
  static const int _stepLocation = 2;
  static const int _stepVehicle = 3;
  static const int _lastStep = _stepVehicle;

  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static const _vehicles = [
    ('BICYCLE', Icons.pedal_bike_outlined),
    ('SCOOTER', Icons.moped_outlined),
    ('MOTORCYCLE', Icons.two_wheeler_outlined),
    ('CAR', Icons.directions_car_outlined),
  ];

  String _vehicle = 'SCOOTER';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _licenseNumberCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(Object e) {
    final message = e.toString().replaceFirst('Exception: ', '').replaceFirst('TimeoutException after', 'Request timed out after');
    return message.isNotEmpty ? message : 'Something went wrong. Please try again.';
  }

  // ---- Step 1: Email -> send-otp ----

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _toast('Please enter your email');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _toast('Enter a valid email');
      return;
    }

    setState(() => _sendingOtp = true);
    try {
      await AuthService().sendOtp(email: email);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _step = _stepOtp;
      });
      _toast('OTP sent successfully');
    } catch (e) {
      if (!mounted) return;
      _toast(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  // ---- Step 2: OTP -> verify-otp ----

  Future<void> _verifyOtpAndContinue() async {
    if (!_otpSent) {
      _toast('Please request an OTP first');
      return;
    }
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      _toast('Please enter the OTP sent to your email');
      return;
    }

    setState(() => _verifyingOtp = true);
    try {
      await AuthService().verifyOtp(email: _emailCtrl.text.trim(), otp: otp);
      if (!mounted) return;
      setState(() {
        _otpVerified = true;
        _step = _stepLocation;
      });
      // Best-effort: prompt for location as soon as we land on the
      // Location step, same as the web app does.
      _useCurrentLocation();
    } catch (e) {
      if (!mounted) return;
      _toast(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  // ---- Step 3: Location -> geolocation + nominatim reverse geocode ----

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _toast('Please turn on location services to auto-fill your city');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _toast('Location permission is needed to confirm your city');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;

      final details = await AuthService().reverseGeocodeDetailed(lat: position.latitude, lon: position.longitude);
      if (!mounted) return;
      setState(() {
        _address = details['address'] ?? _address;
        if ((details['city'] ?? '').isNotEmpty) _cityCtrl.text = details['city']!;
        if ((details['state'] ?? '').isNotEmpty) _stateCtrl.text = details['state']!;
      });
    } catch (_) {
      // Silent - rider can still type city/state manually.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  bool _validateLocationStep() {
    if (_nameCtrl.text.trim().isEmpty) {
      _toast('Please enter your full name');
      return false;
    }
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _toast('Please enter your phone number');
      return false;
    }
    if (phone.length < 10) {
      _toast('Please enter a valid phone number');
      return false;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      _toast('Please enter your city');
      return false;
    }
    if (_stateCtrl.text.trim().isEmpty) {
      _toast('Please enter your state');
      return false;
    }
    return true;
  }

  // ---- Step 4: Vehicle -> final signup ----

  Future<void> _createAccount(AppState app) async {
    final vehicleNumber = _vehicleNumberCtrl.text.trim();
    if (vehicleNumber.isEmpty) {
      _toast('Please enter your vehicle number');
      return;
    }
    final licenseNumber = _licenseNumberCtrl.text.trim();
    if (licenseNumber.isEmpty) {
      _toast('Please enter your license number');
      return;
    }
    if (!_otpVerified) {
      _toast('Please verify your email OTP first');
      return;
    }

    setState(() => _creatingAccount = true);
    try {
      final authResponse = await AuthService().signup(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        vehicleType: _vehicle,
        vehicleNumber: vehicleNumber,
        licenseNumber: licenseNumber,
        otp: _otpCtrl.text.trim(),
        address: _address,
        latitude: _latitude,
        longitude: _longitude,
      );
      if (!mounted) return;

      app.setAuthenticatedUser(
        accessToken: authResponse.accessToken,
        partnerId: authResponse.partner.id,
        partnerName: authResponse.partner.name,
        partnerEmail: authResponse.partner.email,
        partnerStatus: authResponse.partner.status,
        vehicleType: authResponse.partner.vehicleType,
      );

      // Same as the web app: account created -> straight to document
      // verification (this app's stand-in for the web's "Documents" step).
      app.startNewApplication();
    } catch (e) {
      if (!mounted) return;
      _toast(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _creatingAccount = false);
    }
  }

  Future<void> _onContinue(AppState app) async {
    switch (_step) {
      case _stepEmail:
        await _sendOtp();
        return;
      case _stepOtp:
        await _verifyOtpAndContinue();
        return;
      case _stepLocation:
        if (_validateLocationStep()) {
          setState(() => _step = _stepVehicle);
        }
        return;
      case _stepVehicle:
        await _createAccount(app);
        return;
    }
  }

  void _goBackAStep() {
    final app = ref.read(appControllerProvider);
    if (_step == _stepEmail) {
      app.back();
      return;
    }
    setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.read(appControllerProvider);
    final busy = _sendingOtp || _verifyingOtp || _creatingAccount;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.screenPadding(context, horizontal: 20, vertical: 4).copyWith(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: 'Sign up to deliver',
                onBack: _goBackAStep,
              ),

              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  "Get verified. Start delivering. Signup requests are approved by our operations team.",
                  style: AppText.body(
                    size: 13,
                    color: AppColors.bodyGrey,
                    height: 1.45,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Step ${_step + 1} of 5 · ${_stepLabel(_step)}',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),

              if (_step == _stepEmail) ...[
                _label('EMAIL ADDRESS'),
                _field(
                  controller: _emailCtrl,
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'An OTP will be sent to this email to verify your account.',
                    style: AppText.body(size: 12, color: AppColors.lightGreyText, height: 1.4),
                  ),
                ),
              ] else if (_step == _stepOtp) ...[
                _label('EMAIL OTP'),
                _field(
                  controller: _otpCtrl,
                  hint: 'Enter OTP',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: _sendingOtp ? null : _sendOtp,
                    child: Text(
                      _sendingOtp ? 'Resending…' : 'Resend OTP',
                      style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.accent),
                    ),
                  ),
                ),
              ] else if (_step == _stepLocation) ...[
                _label('FULL NAME'),
                _field(
                  controller: _nameCtrl,
                  hint: 'As per your ID proof',
                ),
                const SizedBox(height: 14),
                _label('PHONE NUMBER'),
                _field(
                  controller: _phoneCtrl,
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _locating ? null : _useCurrentLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.plumTint,
                      border: Border.all(color: AppColors.plumTintBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _locating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                              )
                            : const Icon(Icons.my_location, size: 18, color: AppColors.accent),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            _locating ? 'Detecting your location…' : 'Use current location to auto-fill city & state',
                            style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _label('CITY'),
                _field(
                  controller: _cityCtrl,
                  hint: "City you'll deliver in",
                ),
                const SizedBox(height: 14),
                _label('STATE'),
                _field(
                  controller: _stateCtrl,
                  hint: 'Enter state',
                ),
              ] else if (_step == _stepVehicle) ...[
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
                          color: selected ? AppColors.accent : Colors.white,
                          border: Border.all(
                            color: selected ? AppColors.accent : AppColors.dividerBorder,
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
                              color: selected ? Colors.white : AppColors.ink,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              v.$1,
                              style: AppText.body(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: selected ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                _label('VEHICLE NUMBER'),
                _field(
                  controller: _vehicleNumberCtrl,
                  hint: 'TS09AB1234',
                ),
                const SizedBox(height: 14),
                _label('LICENSE NUMBER'),
                _field(
                  controller: _licenseNumberCtrl,
                  hint: 'Driving License Number',
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
                          "Step 5 · Documents: after you create your account, you'll upload your driving licence, vehicle RC and insurance for verification.",
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
              ],

              const SizedBox(height: 20),

              GestureDetector(
                onTap: busy ? null : () => _onContinue(app),
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
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _step < _lastStep ? 'Continue' : 'Create account',
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

  String _stepLabel(int step) {
    switch (step) {
      case _stepEmail:
        return 'Email';
      case _stepOtp:
        return 'OTP';
      case _stepLocation:
        return 'Location';
      case _stepVehicle:
        return 'Vehicle';
      default:
        return '';
    }
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
