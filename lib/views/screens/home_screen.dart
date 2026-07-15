import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/app_models.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../widgets/rider_map.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _radar = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _radar.dispose();
    super.dispose();
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_greeting, rider', style: AppText.body(size: 12.5, color: AppColors.bodyGrey)),
                      Text(app.displayName(riderName), style: AppText.display(size: 21, letterSpacing: -0.3)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: app.toProfile,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.plumTint, border: Border.all(color: AppColors.plumTintBorder, width: 1.5)),
                    alignment: Alignment.center,
                    child: Text(app.displayInitials(riderInitials), style: AppText.body(size: 15, weight: FontWeight.w800, color: AppColors.accent)),
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
                  padding: app.online ? EdgeInsets.zero : const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: app.online ? Colors.transparent : Colors.white,
                    border: Border.all(color: app.online ? Colors.transparent : AppColors.dividerBorder2, width: 1.5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: app.online ? _onlineHero() : _offlineHero(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TODAY', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1)),
                GestureDetector(onTap: app.toEarnings, child: Text('Earnings →', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent))),
              ],
            ),
            const SizedBox(height: 10),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Earned today', style: AppText.body(size: 12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                        Text(moneyFmt(todayEarn), style: AppText.display(size: 24, color: Colors.white)),
                        Text('▲ 18% vs yesterday', style: AppText.body(size: 11, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                ),
                _statCard('Trips', '$todayTrips', sub: '$onlineTime online', subColor: AppColors.green),
                _statCard('Distance', '$todayKm km'),
                GestureDetector(onTap: app.toRatings, child: _statCard('Rating', '4.9', star: true)),
              ],
            ),
            if (app.incentiveOffer != null) ...[
              const SizedBox(height: 16),
              _incentiveCard(app.incentiveOffer!),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent trips', style: AppText.display(size: 16)),
                GestureDetector(onTap: app.toHistory, child: Text('View all →', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.accent))),
              ],
            ),
            const SizedBox(height: 11),
            ...recentTrips.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.plumTint, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Icon(t.icon, size: 20, color: AppColors.accent)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.restaurant, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 13.5, weight: FontWeight.w700)),
                            Text('${t.when} · ${t.km} km', style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                          ],
                        ),
                      ),
                      Text('+₹${t.pay}', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.green)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _onlineHero() {

  return SizedBox(

    height: 260,

    child: Stack(

      children: [

        ClipRRect(

          borderRadius: BorderRadius.circular(20),

          child: SizedBox.expand(

            child: const RiderMap(),

          ),

        ),

        Center(

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Container(

                width: 56,

                height: 56,

                decoration: BoxDecoration(

                  color: Colors.green,

                  shape: BoxShape.circle,

                  boxShadow: [

                    BoxShadow(

                      color: Colors.green.withOpacity(.4),

                      blurRadius: 20,

                    ),

                  ],

                ),

                child: const Center(

                  child: Icon(

                    Icons.location_on,

                    color: Colors.white,

                  ),

                ),

              ),

              const SizedBox(height: 15),

              Text(

                "You're online",

                style: AppText.display(

                  size: 18,

                ),

              ),

              const SizedBox(height: 5),

              Text(

                "Finding orders near Banjara Hills...",

                style: AppText.body(

                  size: 12,

                  color: Colors.black87,

                ),

              ),

              const SizedBox(height: 15),

              Container(

                padding: const EdgeInsets.symmetric(

                  horizontal: 16,

                  vertical: 10,

                ),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(12),

                ),

                child: GestureDetector(

                  onTap: () {

                    ref.read(appControllerProvider).openAlert();

                  },

                  child: Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      const Icon(

                        Icons.circle,

                        color: Colors.green,

                        size: 10,

                      ),

                      const SizedBox(width: 8),

                      const Text("LIVE"),

                      const SizedBox(width: 12),

                      Container(

                        width: 1,

                        height: 15,

                        color: Colors.grey,

                      ),

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

  );
}
  Widget _offlineHero() {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: const Icon(Icons.power_settings_new, size: 24, color: AppColors.midGrey)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You're offline", style: AppText.display(size: 17)),
                Text('Tap to go online and start receiving orders', style: AppText.body(size: 12, color: AppColors.bodyGrey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 46, height: 27, decoration: BoxDecoration(color: const Color(0xFFD9CEC6), borderRadius: BorderRadius.circular(20)), child: Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Container(width: 21, height: 21, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))]))))),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, {String? sub, Color? subColor, bool star = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.bodyGrey)),
          Row(children: [
            Text(value, style: AppText.display(size: 21)),
            if (star) ...[const SizedBox(width: 5), const Text('★', style: TextStyle(color: AppColors.star, fontSize: 16))],
          ]),
          if (sub != null) Text(sub, style: AppText.body(size: 11, weight: FontWeight.w600, color: subColor ?? AppColors.bodyGrey)),
        ],
      ),
    );
  }

  Widget _incentiveCard(IncentiveOffer offer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      decoration: BoxDecoration(gradient: AppColors.incentiveGradient, border: Border.all(color: AppColors.goldTintBorder2, width: 1.5), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.track_changes_outlined, size: 20, color: Color(0xFF7A4E12)),
                const SizedBox(width: 9),
                Text('Trip streak bonus', style: AppText.display(size: 14, color: const Color(0xFF7A4E12))),
              ]),
              Text('+₹${offer.bonusAmount}', style: AppText.body(size: 14, weight: FontWeight.w800, color: const Color(0xFF7A4E12))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: RichText(
              text: TextSpan(style: AppText.body(size: 12, color: const Color(0xFF9A7534)), children: [
                const TextSpan(text: 'Complete '),
                TextSpan(text: '${offer.remainingTrips} more trip${offer.remainingTrips == 1 ? '' : 's'}', style: const TextStyle(color: Color(0xFF7A4E12), fontWeight: FontWeight.w700)),
                TextSpan(text: ' ${offer.deadlineLabel} to unlock the bonus'),
              ]),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 11),
            height: 9,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: const Color(0xFF7A4E12).withValues(alpha: 0.15)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: offer.progress,
              child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDeep]))),
            ),
          ),
          Padding(padding: const EdgeInsets.only(top: 6), child: Text('${offer.currentTrips} OF ${offer.targetTrips} TRIPS', style: AppText.body(size: 10.5, weight: FontWeight.w700, color: const Color(0xFF9A7534), letterSpacing: 0.3))),
        ],
      ),
    );
  }
}
