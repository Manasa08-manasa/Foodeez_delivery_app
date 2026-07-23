import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../models/app_models.dart';
import '../services/delivery_assignments_api.dart';
import '../services/delivery_partners_api.dart';
import '../services/delivery_socket_service.dart';
import '../services/delivery_tracking_api.dart';

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

  DeliverySocketService? _deliverySocket;
  String? _deliverySocketPartnerId;
  Timer? _locationTimer;
  Timer? _assignmentPollTimer;
  DateTime? _lastLocationPushAt;
  double? _lastLatitude;
  double? _lastLongitude;
  String? _lastLocationStatus;
  List<Map<String, dynamic>> activeRiders = const [];

  String earnPeriod = 'today';

  final Map<String, bool> prefs = {'longTrips': true, 'autoAccept': false, 'cashOnly': false};

  /// Set by Foodeez ops/fleet-manager backend when a streak-bonus campaign is
  /// running for this rider — riders cannot activate this themselves. Null
  /// means no campaign is running, and the Home screen shows nothing in its
  /// place (Recent trips simply moves up to fill the space).
  IncentiveOffer? incentiveOffer;

  void setIncentiveOffer(IncentiveOffer? offer) {
    incentiveOffer = offer;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _locationTimer?.cancel();
    _assignmentPollTimer?.cancel();
    _deliverySocket?.disconnect();
    _deliverySocket = null;
    _deliverySocketPartnerId = null;
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
    _locationTimer?.cancel();
    _assignmentPollTimer?.cancel();
    _deliverySocket?.disconnect();
    _deliverySocket = null;
    _deliverySocketPartnerId = null;

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

    // If the user is already marked online, start listening immediately for new orders.
    _maybeStartDeliveryRealtime();
    _startLocationTracking();
    _startAssignmentPolling();
  }

  static const _hideTabScreens = {'login', 'signup', 'trip', 'tripdone', 'help'};
  bool get showTabBar => !_hideTabScreens.contains(screen) && accountStatus == AccountStatus.active;

  static const _activeTabFor = {'home': 'home', 'history': 'history', 'earnings': 'earnings', 'profile': 'profile', 'ratings': 'profile'};
  String get activeTab => _activeTabFor[screen] ?? '';

  // ---- online / incoming request ----

  void toggleOnline() {
    if (accountStatus != AccountStatus.active) return;

    final prev = online;
    final next = !online;
    online = next;
    notifyListeners();

    if (next) {
      _maybeStartDeliveryRealtime();
      _startLocationTracking();
      _startAssignmentPolling();
    } else {
      _stopDeliveryRealtime();
      _stopLocationTracking();
      _stopAssignmentPolling();
    }

    // Best-effort: update online status on backend so it can dispatch assignments to us.
    final token = accessToken;
    final pid = partnerId;
    if (token == null || pid == null || pid.isEmpty) return;

    unawaited(() async {
      try {
        await DeliveryPartnersApi().toggleOnline(accessToken: token, partnerId: pid, isOnline: next);
      } catch (_) {
        // Revert local online state if backend rejects.
        online = prev;
        if (online) {
          _maybeStartDeliveryRealtime();
        } else {
          _stopDeliveryRealtime();
        }
        notifyListeners();
      }
    }());
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

    // If backend provided an accept deadline, drive the countdown from it.
    final deadline = activeRequest?.acceptDeadlineAt;
    if (deadline != null) {
      final secs = deadline.difference(DateTime.now()).inSeconds;
      alertCountdown = secs.clamp(0, 9999);
    } else {
      alertCountdown = alertCountdown.clamp(0, 9999);
    }

    if (alertCountdown <= 0) {
      _dismissAlertLocal();
      return;
    }

    _alertTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!alertOpen) {
        t.cancel();
        return;
      }
      if (alertCountdown <= 1) {
        t.cancel();
        // Backend will auto-cancel/reassign on expiry; locally dismiss the alert.
        _dismissAlertLocal();
        return;
      }
      alertCountdown -= 1;
      notifyListeners();
    });
  }

  void acceptAlert() {
    _alertTimer?.cancel();

    final req = activeRequest;
    final assignmentId = req?.assignmentId ?? '';
    final token = accessToken;
    final pid = partnerId;

    alertOpen = false;
    notifyListeners();

    unawaited(() async {
      // If this is a demo request (assignmentId is empty), accept locally.
      if (assignmentId.isEmpty || token == null || pid == null || pid.isEmpty) {
        _acceptLocally();
        return;
      }

      try {
        await DeliveryAssignmentsApi().claim(accessToken: token, assignmentId: assignmentId, partnerId: pid);
        _acceptLocally();
      } catch (_) {
        // If another rider claimed it first, re-open locally until the next websocket update.
        if (req?.acceptDeadlineAt != null) {
          alertOpen = true;
          _startAlertCountdown();
        }
        notifyListeners();
      }
    }());
  }

  void _acceptLocally() {
    stage = DeliveryStage.toPickup;
    pickupOtp = '';
    dropOtp = '';
    codCollected = false;
    stack = ['home', 'trip'];
    notifyListeners();
  }

  void rejectAlert() {
    _alertTimer?.cancel();

    final req = activeRequest;
    final assignmentId = req?.assignmentId ?? '';
    final token = accessToken;
    final pid = partnerId;

    alertOpen = false;
    notifyListeners();

    // Decline the assignment on backend (for real incoming orders).
    if (assignmentId.isEmpty || token == null || pid == null || pid.isEmpty) return;

    unawaited(() async {
      try {
        await DeliveryAssignmentsApi().reject(
          accessToken: token,
          assignmentId: assignmentId,
          partnerId: pid,
          reason: 'Rider rejected',
        );
      } catch (_) {
        // Best-effort: keep local dismissal even if backend fails.
      }
    }());
  }

  void _dismissAlertLocal() {
    _alertTimer?.cancel();
    alertOpen = false;
    notifyListeners();
  }

  void _handleWsNewAssignment(WsDeliveryAssignment ws) {
    // Only show incoming offers on Home (Trip flow already blocks availability).
    if (accountStatus != AccountStatus.active) return;
    if (screen != 'home') return;

    activeRequest = _mergeWsIntoDemoRequest(ws);
    alertOpen = true;
    // Reset local step state for the incoming flow.
    stage = DeliveryStage.toPickup;
    pickupOtp = '';
    dropOtp = '';
    codCollected = false;

    _startAlertCountdown();
    notifyListeners();
  }

  DeliveryRequest _mergeWsIntoDemoRequest(WsDeliveryAssignment ws) {
    final base = demoRequest;
    return DeliveryRequest(
      assignmentId: ws.assignmentId,
      orderId: ws.orderId,
      restaurantName: base.restaurantName,
      restaurantAddress: base.restaurantAddress,
      customerName: base.customerName,
      customerAddress: (ws.customerAddress != null && ws.customerAddress!.trim().isNotEmpty) ? ws.customerAddress!.trim() : base.customerAddress,
      totalKm: ws.estimatedDistanceKm ?? base.totalKm,
      totalMins: ws.estimatedDurationMins ?? base.totalMins,
      payout: ws.deliveryFee.round(),
      orderTotal: base.orderTotal,
      paymentMethod: base.paymentMethod,
      items: base.items,
      acceptDeadlineAt: ws.acceptDeadlineAt,
    );
  }

  void _handleWsAssignmentCancelled(String assignmentId) {
    if (!alertOpen) return;
    if ((activeRequest?.assignmentId ?? '') != assignmentId) return;
    _dismissAlertLocal();
  }

  void _maybeStartDeliveryRealtime() {
    final pid = partnerId;
    if (pid == null || pid.isEmpty) return;
    if (!online) return;
    if (accountStatus != AccountStatus.active) return;
    if (_deliverySocket != null && _deliverySocketPartnerId == pid) return;

    _deliverySocket?.disconnect();
    _deliverySocket = DeliverySocketService();
    _deliverySocketPartnerId = pid;
    _deliverySocket!.connect(
      partnerId: pid,
      onNewAssignment: _handleWsNewAssignment,
      onAssignmentCancelled: _handleWsAssignmentCancelled,
    );
  }

  void _stopDeliveryRealtime() {
    _deliverySocket?.disconnect();
    _deliverySocket = null;
    _deliverySocketPartnerId = null;
  }

  Future<void> refreshActiveRiders() async {
    final token = accessToken;
    if (token == null || token.isEmpty) return;

    try {
      final riders = await DeliveryTrackingApi().activeRiders(accessToken: token);
      activeRiders = riders;
      notifyListeners();
    } catch (_) {
      activeRiders = const [];
      notifyListeners();
    }
  }

  Future<void> refreshIncomingAssignments() async {
    final token = accessToken;
    final pid = partnerId;
    if (token == null || token.isEmpty || pid == null || pid.isEmpty) return;
    if (!online || accountStatus != AccountStatus.active) return;

    try {
      final items = await DeliveryAssignmentsApi().byPartner(
        accessToken: token,
        partnerId: pid,
        page: 1,
        limit: 20,
      );

      final pending = <DeliveryRequest>[];
      for (final item in items) {
        final req = _mapAssignmentToDeliveryRequest(item);
        if (req == null) continue;
        final status = (item['status'] ?? '').toString().toUpperCase();
        if (status.isEmpty || ['ASSIGNED', 'PENDING', 'NEW', 'WAITING_FOR_RIDER', 'READY_FOR_PICKUP'].contains(status)) {
          pending.add(req);
        }
      }

      if (pending.isEmpty) return;

      final next = pending.first;
      final sameAssignment = (activeRequest?.assignmentId ?? '') == next.assignmentId;
      final inTripFlow = stack.contains('trip') || stack.contains('tripdone');
      if (sameAssignment || inTripFlow) return;

      activeRequest = next;
      alertOpen = true;
      stage = DeliveryStage.toPickup;
      pickupOtp = '';
      dropOtp = '';
      codCollected = false;
      _startAlertCountdown();
      notifyListeners();
    } catch (_) {
      // Stay resilient if the backend assignment list is temporarily unavailable.
    }
  }

  DeliveryRequest? _mapAssignmentToDeliveryRequest(Map<String, dynamic> item) {
    final assignmentId = _readString(item, ['id', 'assignmentId', 'assignment_id']);
    if (assignmentId == null || assignmentId.isEmpty) return null;

    final base = demoRequest;
    final orderId = _readString(item, ['orderId', 'order_id', 'orderNumber', 'order_number']) ?? '';
    final restaurantName = _readString(item, ['restaurantName', 'restaurant_name', 'restaurant', 'restaurantName']) ?? base.restaurantName;
    final restaurantAddress = _readString(item, ['restaurantAddress', 'restaurant_address', 'restaurantAddressLine', 'restaurant_address_line']) ?? base.restaurantAddress;
    final customerName = _readString(item, ['customerName', 'customer_name', 'customer', 'name']) ?? base.customerName;
    final customerAddress = _readString(item, ['customerAddress', 'customer_address', 'dropAddress', 'deliveryAddress', 'delivery_address']) ?? base.customerAddress;
    final payout = _readInt(item, ['deliveryFee', 'delivery_fee', 'payout']) ?? base.payout;
    final distance = _readDouble(item, ['estimatedDistanceKm', 'estimated_distance_km']) ?? base.totalKm;
    final duration = _readInt(item, ['estimatedDurationMins', 'estimated_duration_mins']) ?? base.totalMins;

    return DeliveryRequest(
      assignmentId: assignmentId,
      orderId: orderId,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      customerName: customerName,
      customerAddress: customerAddress,
      totalKm: distance,
      totalMins: duration,
      payout: payout,
      orderTotal: base.orderTotal,
      paymentMethod: base.paymentMethod,
      items: base.items,
      acceptDeadlineAt: _readDate(item, ['acceptDeadlineAt', 'accept_deadline_at', 'expiresAt', 'expires_at']),
    );
  }

  String? _readString(Map<String, dynamic> item, List<String> candidates) {
    final found = _findValue(item, candidates);
    if (found == null) return null;
    final text = found.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _readInt(Map<String, dynamic> item, List<String> candidates) {
    final found = _findValue(item, candidates);
    if (found == null) return null;
    if (found is int) return found;
    if (found is num) return found.toInt();
    return int.tryParse(found.toString());
  }

  double? _readDouble(Map<String, dynamic> item, List<String> candidates) {
    final found = _findValue(item, candidates);
    if (found == null) return null;
    if (found is num) return found.toDouble();
    return double.tryParse(found.toString());
  }

  DateTime? _readDate(Map<String, dynamic> item, List<String> candidates) {
    final found = _findValue(item, candidates);
    if (found == null) return null;
    if (found is DateTime) return found;
    final text = found.toString();
    return text.isEmpty ? null : DateTime.tryParse(text);
  }

  dynamic _findValue(dynamic node, List<String> candidates) {
    if (node is Map) {
      final map = Map<String, dynamic>.from(node);
      for (final candidate in candidates) {
        if (map.containsKey(candidate)) return map[candidate];
      }
      for (final value in map.values) {
        final found = _findValue(value, candidates);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findValue(item, candidates);
        if (found != null) return found;
      }
    }
    return null;
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    final token = accessToken;
    final pid = partnerId;
    if (token == null || pid == null || pid.isEmpty) return;
    if (!online) return;
    if (accountStatus != AccountStatus.active) return;

    _locationTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      await _pushLocationPulse();
    });

    unawaited(_pushLocationPulse());
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _startAssignmentPolling() {
    _assignmentPollTimer?.cancel();
    if (!online || accountStatus != AccountStatus.active) return;

    _assignmentPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(refreshIncomingAssignments());
    });

    unawaited(refreshIncomingAssignments());
  }

  void _stopAssignmentPolling() {
    _assignmentPollTimer?.cancel();
    _assignmentPollTimer = null;
  }

  Future<void> _pushLocationPulse() async {
    final token = accessToken;
    final pid = partnerId;
    if (token == null || pid == null || pid.isEmpty) return;
    if (!online) return;
    if (accountStatus != AccountStatus.active) return;

    final now = DateTime.now();
    if (_lastLocationPushAt != null && now.difference(_lastLocationPushAt!).inSeconds < 10) {
      return;
    }

    // Use a conservative fallback location for now so the backend receives a valid payload.
    const fallbackLatitude = 17.4126;
    const fallbackLongitude = 78.4482;

    try {
      await DeliveryTrackingApi().shareLocation(
        accessToken: token,
        partnerId: pid,
        latitude: _lastLatitude ?? fallbackLatitude,
        longitude: _lastLongitude ?? fallbackLongitude,
        status: _lastLocationStatus ?? (online ? 'ONLINE' : 'OFFLINE'),
      );
      _lastLocationPushAt = now;
    } catch (_) {
      // Keep the UI resilient if the tracking endpoint is unavailable.
    }
  }

  void updateLastKnownLocation({required double latitude, required double longitude, String? status}) {
    _lastLatitude = latitude;
    _lastLongitude = longitude;
    _lastLocationStatus = status;
    notifyListeners();
  }

  // ---- live trip ----

  void nextStage() {
    final req = activeRequest;
    final assignmentId = req?.assignmentId ?? '';
    final token = accessToken;

    final prevStage = stage;

    unawaited(() async {
      // If this is a demo request, just advance locally.
      if (assignmentId.isEmpty || token == null) {
        _advanceStageLocally();
        return;
      }

      final nextStatus = _apiStatusForNextTransition(prevStage);
      if (nextStatus == null) return;

      try {
        await DeliveryAssignmentsApi().updateStatus(
          accessToken: token,
          assignmentId: assignmentId,
          status: nextStatus,
        );
      } catch (_) {
        // If backend rejects status transition, keep UI as-is.
        return;
      }

      _advanceStageLocally();
    }());
  }

  void _advanceStageLocally() {
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

  /// Map local [DeliveryStage] button-press to backend DeliveryStatus for the next stage.
  String? _apiStatusForNextTransition(DeliveryStage s) {
    switch (s) {
      case DeliveryStage.toPickup:
        return 'PICKED_UP';
      case DeliveryStage.atPickup:
        return 'ON_THE_WAY';
      case DeliveryStage.toDrop:
        return 'ARRIVED';
      case DeliveryStage.atDrop:
        return 'DELIVERED';
    }
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
