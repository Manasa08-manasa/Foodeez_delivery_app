import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../models/app_models.dart';

/// Mirrors the design prototype's `Component` state machine: a screen stack
/// for push/pop flows, plus a "tab reset" mode for the 4 bottom-dock destinations.
class AppState extends ChangeNotifier {
  List<String> stack = ['login'];
  String get screen => stack.last;

  bool online = true;
  String? accessToken;
  String? partnerId;
  String? partnerName;
  String? partnerEmail;
  String? partnerStatus;
  String? vehicleType;

  /// Display helpers used by Home/Profile so they show the real, logged-in
  /// partner's data once available, and fall back to the bundled demo
  /// persona (mock_data.dart) only when nobody has actually authenticated
  /// yet (e.g. mid-signup, before doc verification).
  String displayName(String fallback) => (partnerName != null && partnerName!.trim().isNotEmpty) ? partnerName! : fallback;

  String displayInitials(String fallback) {
    final name = partnerName?.trim();
    if (name == null || name.isEmpty) return fallback;
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return fallback;
    final initials = parts.length == 1 ? parts.first.substring(0, 1) : (parts.first.substring(0, 1) + parts.last.substring(0, 1));
    return initials.toUpperCase();
  }

  String displayId(String fallback) => (partnerId != null && partnerId!.trim().isNotEmpty) ? partnerId! : fallback;

  // ---- account activation / documents ----

  /// The established demo persona (logs straight into Home) already has a
  /// fully-verified account. A fresh signup starts at [pendingReview].
  AccountStatus accountStatus = AccountStatus.active;

  final Map<String, String> documentNumbers = {...seedDocumentNumbers};
  final Map<String, DocumentStatus> documentStatus = {
    for (final d in verifiableDocuments) d.id: DocumentStatus.verified,
  };
  final Map<String, bool> documentUploaded = {for (final d in verifiableDocuments) d.id: true};

  void setDocumentNumber(String id, String value) {
    documentNumbers[id] = value;
    notifyListeners();
  }

  /// Simulates picking a file for the document (photo of the physical
  /// document) — there's no real file storage in this mock, so it just
  /// flips a submitted flag.
  void uploadDocument(String id) {
    documentUploaded[id] = true;
    notifyListeners();
  }

  void verifyDocument(String id) {
    final status = documentStatus[id] ?? DocumentStatus.unverified;
    if (status == DocumentStatus.pending || status == DocumentStatus.verified) return;
    if ((documentNumbers[id] ?? '').trim().isEmpty) return;
    documentStatus[id] = DocumentStatus.pending;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1400), () {
      documentStatus[id] = DocumentStatus.verified;
      notifyListeners();
    });
  }

  bool _docDone(VerifiableDocument d) => documentUploaded[d.id] == true && (!d.requiresNumber || documentStatus[d.id] == DocumentStatus.verified);

  bool get allDocumentsVerified => verifiableDocuments.every(_docDone);

  /// Resets the account to a brand-new, unverified signup and drops the
  /// rider straight onto the document-verification screen — called after
  /// the rider-registration form is submitted. They cannot reach Home,
  /// Trips or Earnings until an admin activates the account (enforced in
  /// `AppShell`, see main.dart).
  void startNewApplication() {
    accountStatus = AccountStatus.pendingReview;
    online = false;
    documentNumbers.clear();
    for (final d in verifiableDocuments) {
      documentStatus[d.id] = DocumentStatus.unverified;
      documentUploaded[d.id] = false;
    }
    stack = ['profile'];
    notifyListeners();
  }

  /// Demo-only affordance to simulate an admin approving a pending application.
  void simulateAdminApproval() {
    accountStatus = AccountStatus.active;
    notifyListeners();
  }

  bool alertOpen = false;
  int alertCountdown = 15;
  Timer? _alertTimer;

  DeliveryStage stage = DeliveryStage.toPickup;
  String pickupOtp = '';
  String dropOtp = '';
  bool codCollected = false;
  DeliveryRequest? activeRequest;

  String earnPeriod = 'today';

  final Map<String, bool> prefs = {'longTrips': true, 'autoAccept': false, 'cashOnly': false};

  /// Set by Foodeez ops/fleet-manager backend when a streak-bonus campaign is
  /// running for this rider — riders cannot activate this themselves. Null
  /// means no campaign is running, and the Home screen shows nothing in its
  /// place (Recent trips simply moves up to fill the space).
  IncentiveOffer? incentiveOffer = demoIncentive;

  void setIncentiveOffer(IncentiveOffer? offer) {
    incentiveOffer = offer;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  // ---- navigation ----

  void go(String s) {
    stack = [...stack, s];
    notifyListeners();
  }

  void back() {
    if (stack.length > 1) {
      stack = stack.sublist(0, stack.length - 1);
    } else {
      stack = ['home'];
    }
    notifyListeners();
  }

  void tab(String s) {
    stack = [s];
    notifyListeners();
  }

  void toHome() => tab('home');
  void toProfile() => tab('profile');
  void toEarnings() => tab('earnings');
  void toHistory() => tab('history');
  void toRatings() => go('ratings');
  void toHelp() => go('help');

  void logout() {
    accessToken = null;
    partnerId = null;
    partnerName = null;
    partnerEmail = null;
    partnerStatus = null;
    vehicleType = null;
    stack = ['login'];
    notifyListeners();
  }

  void setAuthenticatedUser({required String accessToken, required String partnerId, required String partnerName, required String partnerEmail, required String partnerStatus, required String vehicleType}) {
    this.accessToken = accessToken;
    this.partnerId = partnerId;
    this.partnerName = partnerName;
    this.partnerEmail = partnerEmail;
    this.partnerStatus = partnerStatus;
    this.vehicleType = vehicleType;
    accountStatus = AccountStatus.active;
    notifyListeners();
  }

  static const _hideTabScreens = {'login', 'signup', 'trip', 'tripdone', 'help'};
  bool get showTabBar => !_hideTabScreens.contains(screen) && accountStatus == AccountStatus.active;

  static const _activeTabFor = {'home': 'home', 'history': 'history', 'earnings': 'earnings', 'profile': 'profile', 'ratings': 'profile'};
  String get activeTab => _activeTabFor[screen] ?? '';

  // ---- online / incoming request ----

  void toggleOnline() {
    if (accountStatus != AccountStatus.active) return;
    online = !online;
    notifyListeners();
  }

  /// Demo trigger for "Simulate an order" — in production the request arrives
  /// via push/websocket from the dispatch service instead.
  void openAlert() {
    activeRequest = demoRequest;
    alertOpen = true;
    alertCountdown = 15;
    _startAlertCountdown();
    notifyListeners();
  }

  void _startAlertCountdown() {
    _alertTimer?.cancel();
    _alertTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!alertOpen) {
        t.cancel();
        return;
      }
      if (alertCountdown <= 1) {
        t.cancel();
        rejectAlert(); // auto-decline once the response window elapses
        return;
      }
      alertCountdown -= 1;
      notifyListeners();
    });
  }

  void acceptAlert() {
    _alertTimer?.cancel();
    alertOpen = false;
    stage = DeliveryStage.toPickup;
    pickupOtp = '';
    dropOtp = '';
    codCollected = false;
    stack = ['home', 'trip'];
    notifyListeners();
  }

  void rejectAlert() {
    _alertTimer?.cancel();
    alertOpen = false;
    notifyListeners();
  }

  // ---- live trip ----

  void nextStage() {
    switch (stage) {
      case DeliveryStage.toPickup:
        stage = DeliveryStage.atPickup;
        break;
      case DeliveryStage.atPickup:
        stage = DeliveryStage.toDrop;
        break;
      case DeliveryStage.toDrop:
        stage = DeliveryStage.atDrop;
        break;
      case DeliveryStage.atDrop:
        stack = ['home', 'tripdone'];
        notifyListeners();
        return;
    }
    notifyListeners();
  }

  void setOtp(String digits) {
    final numeric = digits.replaceAll(RegExp(r'\D'), '');
    final trimmed = numeric.length > 4 ? numeric.substring(0, 4) : numeric;
    if (stage == DeliveryStage.atPickup) {
      pickupOtp = trimmed;
    } else if (stage == DeliveryStage.atDrop) {
      dropOtp = trimmed;
    }
    notifyListeners();
  }

  void toggleCod() {
    codCollected = !codCollected;
    notifyListeners();
  }

  String get activeOtp => stage == DeliveryStage.atPickup ? pickupOtp : (stage == DeliveryStage.atDrop ? dropOtp : '');

  bool get otpDone => activeOtp.length >= 4;

  bool get actionReady {
    final req = activeRequest ?? demoRequest;
    if (stage == DeliveryStage.atPickup) return otpDone;
    if (stage == DeliveryStage.atDrop) return otpDone && (req.paymentMethod != PaymentMethod.cod || codCollected);
    return true;
  }

  // ---- earnings ----

  void setEarnPeriod(String p) {
    earnPeriod = p;
    notifyListeners();
  }

  EarningsPeriodData get currentEarnings => earningsByPeriod[earnPeriod]!;

  // ---- preferences ----

  void togglePref(String key) {
    prefs[key] = !(prefs[key] ?? false);
    notifyListeners();
  }
}

/// Riverpod entry point for [AppState]. Views obtain the controller with
/// `ref.watch(appControllerProvider)` (rebuilds on every change) or
/// `ref.read(appControllerProvider)` (one-off reads / calling action
/// methods without subscribing to rebuilds) instead of the old
/// `context.watch<AppState>()` / `context.read<AppState>()` calls.
final appControllerProvider = ChangeNotifierProvider<AppState>((ref) => AppState());
