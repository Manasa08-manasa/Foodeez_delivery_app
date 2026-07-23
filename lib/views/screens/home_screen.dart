import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/utils.dart';
import '../widgets/rider_map.dart';
import '../../services/delivery_assignments_api.dart';
import '../../services/delivery_partners_api.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radar = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  int _todayEarn = 0;
  int _todayTrips = 0;
  double _todayKm = 0;
  List<RecentTrip> _recentTrips = const [];
  double? _partnerRating;
  bool _loadingStats = true;
  bool _statsLoaded = false;
  String? _statsError;
  bool _showMap = false;
  bool _fullScreenMap = false;

  @override
  void initState() {
    super.initState();
    // Load earnings/trips in background after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeliveryStats());
  }

  @override
  void dispose() {
    _radar.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryStats() async {
    if (_loadingStats && _statsLoaded) return;

    final app = ref.read(appControllerProvider);
    final token = app.accessToken;
    final partnerId = app.partnerId;
    if (token == null ||
        token.isEmpty ||
        partnerId == null ||
        partnerId.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingStats = false;
          _statsLoaded = false;
        });
      }
      return;
    }

    setState(() {
      _loadingStats = true;
      _statsError = null;
    });

    try {
      final results = await Future.wait([
        DeliveryAssignmentsApi().byPartner(
          accessToken: token,
          partnerId: partnerId,
          page: 1,
          limit: 50,
        ),
        DeliveryPartnersApi().getEarnings(
          accessToken: token,
          partnerId: partnerId,
        ),
      ]);

      final items = results[0] as List<Map<String, dynamic>>;
      final earnings = results[1] as Map<String, dynamic>;

      DateTime? parseDate(Map<String, dynamic> m, List<String> keys) {
        for (final k in keys) {
          final v = m[k];
          if (v == null) continue;
          final s = v.toString();
          if (s.isEmpty) continue;
          final dt = DateTime.tryParse(s);
          if (dt != null) return dt.toLocal();
        }
        return null;
      }

      double? parseDouble(Map<String, dynamic> m, List<String> keys) {
        for (final k in keys) {
          final v = m[k];
          if (v == null) continue;
          if (v is num) return v.toDouble();
          final s = v.toString();
          if (s.isEmpty) continue;
          final d = double.tryParse(s);
          if (d != null) return d;
        }
        return null;
      }

      int payoutFor(Map<String, dynamic> a) {
        final fee = parseDouble(a, ['deliveryFee', 'delivery_fee']) ?? 0;
        final surge =
            parseDouble(a, ['surgeMultiplier', 'surge_multiplier']) ?? 1;
        return (fee * surge).round();
      }

      String formatWhen(DateTime dt) {
        var hour = dt.hour;
        final minute = dt.minute.toString().padLeft(2, '0');
        final ampm = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        return '$hour:$minute $ampm';
      }

      String tripLabel(Map<String, dynamic> a) {
        final orderNumber = a['orderNumber']?.toString();
        if (orderNumber != null && orderNumber.isNotEmpty) {
          return orderNumber.startsWith('#')
              ? 'Order $orderNumber'
              : 'Order #$orderNumber';
        }
        final orderId = a['orderId']?.toString();
        if (orderId != null && orderId.isNotEmpty) {
          final shortId = orderId.length > 8
              ? orderId.substring(0, 8)
              : orderId;
          return 'Order #$shortId';
        }
        return 'Delivery';
      }

      final now = DateTime.now();
      bool isSameDay(DateTime d) =>
          d.year == now.year && d.month == now.month && d.day == now.day;

      int todayEarn = 0;
      int todayTrips = 0;
      double todayKm = 0;

      final completed = <(DateTime?, Map<String, dynamic>)>[];

      for (final a in items) {
        final status = a['status']?.toString().toUpperCase();
        if (status == null) continue;

        final assignedAt = parseDate(a, [
          'assignedAt',
          'assigned_at',
          'createdAt',
          'created_at',
        ]);
        final deliveredAt = parseDate(a, ['deliveredAt', 'delivered_at']);
        final eventAt = status == 'DELIVERED'
            ? (deliveredAt ?? assignedAt)
            : assignedAt;
        completed.add((eventAt, a));

        if (status == 'DELIVERED' && eventAt != null && isSameDay(eventAt)) {
          todayTrips += 1;
          todayEarn += payoutFor(a);
          todayKm +=
              parseDouble(a, [
                'estimatedDistanceKm',
                'estimated_distance_km',
              ]) ??
              0;
        }
      }

      completed.sort((x, y) {
        final dx = x.$1;
        final dy = y.$1;
        if (dx == null && dy == null) return 0;
        if (dx == null) return 1;
        if (dy == null) return -1;
        return dy.compareTo(dx);
      });

      final recent = <RecentTrip>[];
      for (final entry in completed) {
        final dt = entry.$1;
        final a = entry.$2;
        final status = a['status']?.toString().toUpperCase();
        if (dt == null) continue;
        if (status != 'DELIVERED' &&
            status != 'CANCELLED' &&
            status != 'REJECTED')
          continue;

        final km =
            parseDouble(a, ['estimatedDistanceKm', 'estimated_distance_km']) ??
            0;
        final pay = status == 'DELIVERED' ? payoutFor(a) : 0;
        final icon = switch (recent.length % 4) {
          0 => Icons.rice_bowl_outlined,
          1 => Icons.local_pizza_outlined,
          2 => Icons.lunch_dining_outlined,
          _ => Icons.restaurant_menu_outlined,
        };

        recent.add(
          RecentTrip(
            icon: icon,
            restaurant: tripLabel(a),
            when: formatWhen(dt),
            km: km,
            pay: pay,
          ),
        );
        if (recent.length >= 5) break;
      }

      final ratingRaw = earnings['rating'];
      final rating = ratingRaw is num
          ? ratingRaw.toDouble()
          : double.tryParse(ratingRaw?.toString() ?? '');

      if (!mounted) return;
      setState(() {
        _todayEarn = todayEarn;
        _todayTrips = todayTrips;
        _todayKm = todayKm;
        _recentTrips = recent;
        _partnerRating = rating;
        _statsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);

    if (_fullScreenMap) {
      return _buildFullScreenMapView(context);
    }

    ref.listen(appControllerProvider.select((a) => a.accessToken), (
      previous,
      next,
    ) {
      if (next != null && next.isNotEmpty && next != previous) {
        _loadDeliveryStats();
      }
    });

    final ratingLabel = _partnerRating != null && _partnerRating! > 0
        ? _partnerRating!.toStringAsFixed(1)
        : '—';

    return SafeArea(
      child: SingleChildScrollView(
        padding: Responsive.screenPadding(
          context,
          horizontal: 20,
          vertical: 4,
        ).copyWith(bottom: Responsive.isTablet(context) ? 150 : 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting, rider',
                        style: AppText.body(
                          size: 12.5,
                          color: AppColors.bodyGrey,
                        ),
                      ),
                      Text(
                        app.displayName('Rider'),
                        style: AppText.display(size: 21, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: app.toggleOnline,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: app.online ? const Color(0xFFE8F7ED) : const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: app.online ? AppColors.green : AppColors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: app.online ? AppColors.green : AppColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          app.online ? 'ONLINE' : 'OFFLINE',
                          style: AppText.body(
                            size: 12,
                            weight: FontWeight.w700,
                            color: app.online ? AppColors.green : AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: app.toProfile,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.plumTint,
                      border: Border.all(
                        color: AppColors.plumTintBorder,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      app.displayInitials('R'),
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: app.toggleOnline,
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  padding: app.online
                      ? EdgeInsets.zero
                      : const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: app.online ? Colors.transparent : Colors.white,
                    border: Border.all(
                      color: app.online
                          ? Colors.transparent
                          : AppColors.dividerBorder2,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: app.online ? _onlineHero() : _offlineHero(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live map',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.bodyGrey,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showMap = !_showMap;
                      _fullScreenMap = _showMap;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showMap ? Icons.visibility_off : Icons.map,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showMap ? 'Hide map' : 'Show map',
                          style: AppText.body(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showMap) ...[
              const SizedBox(height: 16),
              _buildMapPreview(context),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TODAY',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.bodyGrey,
                    letterSpacing: 1,
                  ),
                ),
                GestureDetector(
                  onTap: app.toEarnings,
                  child: Text(
                    'Earnings →',
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loadingStats && !_statsLoaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.accent,
                  ),
                ),
              )
            else ...[
              if (_statsError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statsError!,
                    style: AppText.body(size: 12.5, color: Colors.red.shade700),
                  ),
                ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  GestureDetector(
                    onTap: app.toEarnings,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earned today',
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          Text(
                            moneyFmt(_todayEarn),
                            style: AppText.display(
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                          if (_todayTrips > 0)
                            Text(
                              '$_todayTrips trip${_todayTrips == 1 ? '' : 's'} completed',
                              style: AppText.body(
                                size: 11,
                                weight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _statCard(
                    'Trips',
                    '$_todayTrips',
                    sub: _todayTrips > 0 ? 'Completed today' : 'No trips yet',
                  ),
                  _statCard('Distance', '${_todayKm.round()} km'),
                  GestureDetector(
                    onTap: app.toRatings,
                    child: _statCard(
                      'Rating',
                      ratingLabel,
                      star: _partnerRating != null && _partnerRating! > 0,
                    ),
                  ),
                ],
              ),
            ],
            if (app.incentiveOffer != null) ...[
              const SizedBox(height: 16),
              _incentiveCard(app.incentiveOffer!),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent trips', style: AppText.display(size: 16)),
                GestureDetector(
                  onTap: app.toHistory,
                  child: Text(
                    'View all →',
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            if (_loadingStats && !_statsLoaded)
              const SizedBox.shrink()
            else if (_recentTrips.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'No recent trips yet',
                  style: AppText.body(size: 13, color: AppColors.bodyGrey),
                ),
              )
            else
              ..._recentTrips.map(
                (t) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.plumTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(t.icon, size: 20, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.restaurant,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(
                                size: 13.5,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${t.when} · ${t.km} km',
                              style: AppText.body(
                                size: 11.5,
                                color: AppColors.bodyGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        t.pay > 0 ? '+₹${t.pay}' : '—',
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w800,
                          color: t.pay > 0
                              ? AppColors.green
                              : AppColors.bodyGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _onlineHero() {
    return SizedBox(
      height: 140,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.onlineHeroGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.goldTintBorder2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.greenPaleBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.location_on, color: AppColors.green, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're online",
                    style: AppText.display(size: 18, color: AppColors.accentDeep),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Finding orders near Banjara Hills...',
                    style: AppText.body(size: 12, color: AppColors.midGrey2),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(appControllerProvider).openAlert();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, color: Colors.green, size: 10),
                          const SizedBox(width: 8),
                          const Text("LIVE"),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 15, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            "Simulate an order →",
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offlineHero() {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.power_settings_new,
              size: 24,
              color: AppColors.midGrey,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You're offline", style: AppText.display(size: 17)),
                Text(
                  'Tap to go online and start receiving orders',
                  style: AppText.body(size: 12, color: AppColors.bodyGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 27,
            decoration: BoxDecoration(
              color: const Color(0xFFD9CEC6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value, {
    String? sub,
    Color? subColor,
    bool star = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.bodyGrey,
            ),
          ),
          Row(
            children: [
              Text(value, style: AppText.display(size: 21)),
              if (star) ...[
                const SizedBox(width: 5),
                const Text(
                  '★',
                  style: TextStyle(color: AppColors.star, fontSize: 16),
                ),
              ],
            ],
          ),
          if (sub != null)
            Text(
              sub,
              style: AppText.body(
                size: 11,
                weight: FontWeight.w600,
                color: subColor ?? AppColors.bodyGrey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _incentiveCard(IncentiveOffer offer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.incentiveGradient,
        border: Border.all(color: AppColors.goldTintBorder2, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.track_changes_outlined,
                    size: 20,
                    color: Color(0xFF7A4E12),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Trip streak bonus',
                    style: AppText.display(
                      size: 14,
                      color: const Color(0xFF7A4E12),
                    ),
                  ),
                ],
              ),
              Text(
                '+₹${offer.bonusAmount}',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: const Color(0xFF7A4E12),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: RichText(
              text: TextSpan(
                style: AppText.body(size: 12, color: const Color(0xFF9A7534)),
                children: [
                  const TextSpan(text: 'Complete '),
                  TextSpan(
                    text:
                        '${offer.remainingTrips} more trip${offer.remainingTrips == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFF7A4E12),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' ${offer.deadlineLabel} to unlock the bonus'),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 11),
            height: 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF7A4E12).withValues(alpha: 0.15),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: offer.progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDeep],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${offer.currentTrips} OF ${offer.targetTrips} TRIPS',
              style: AppText.body(
                size: 10.5,
                weight: FontWeight.w700,
                color: const Color(0xFF9A7534),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMapPreview(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _fullScreenMap = true;
        });
      },
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              const RiderMap(),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.52),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live location preview',
                        style: AppText.body(
                          size: 12,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Tap to expand',
                        style: AppText.body(
                          size: 11.5,
                          color: Colors.white.withOpacity(0.8),
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

  Widget _buildFullScreenMapView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _fullScreenMap = false;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Live map',
                      style: AppText.display(size: 20, color: AppColors.accent),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _fullScreenMap = false;
                        _showMap = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Hide map',
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: const RiderMap(),
              ),
            ),
          ],
        ),
      ),
    );
  }}
