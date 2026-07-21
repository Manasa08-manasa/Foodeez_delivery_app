import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../widgets/common.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  static const _periods = ['today', 'week', 'month'];
  static const _labels = ['Today', 'Week', 'Month'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final d = app.currentEarnings;

    return SafeArea(
      child: SingleChildScrollView(
        padding: Responsive.screenPadding(context, horizontal: 20, vertical: 4).copyWith(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Earnings', style: AppText.display(size: 20))),
            SegmentedPills(labels: _labels, selectedIndex: _periods.indexOf(app.earnPeriod), onSelect: (i) => app.setEarnPeriod(_periods[i])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accentLight, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.subtitle, style: AppText.body(size: 12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                  Text('₹${d.total}', style: AppText.display(size: 34, color: Colors.white)),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        _statItem(d.trips, 'trips'),
                        const SizedBox(width: 20),
                        _statItem(d.km, 'km'),
                        const SizedBox(width: 20),
                        _statItem(d.hrs, 'hrs online'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Breakdown', style: AppText.display(size: 14)),
            const SizedBox(height: 11),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: d.breakdown
                    .map((b) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                          child: Row(
                            children: [
                              Container(width: 36, height: 36, decoration: BoxDecoration(color: b.tint, borderRadius: BorderRadius.circular(11)), alignment: Alignment.center, child: Icon(b.icon, size: 18, color: _iconColorForTint(b.tint))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.label, style: AppText.body(size: 13, weight: FontWeight.w700)),
                                    Text(b.sub, style: AppText.body(size: 11, color: AppColors.bodyGrey)),
                                  ],
                                ),
                              ),
                              Text(b.amount, style: AppText.body(size: 13.5, weight: FontWeight.w800, color: b.amountColor)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.greenPaleBg, borderRadius: BorderRadius.circular(13)), alignment: Alignment.center, child: const Icon(Icons.account_balance_outlined, size: 21, color: AppColors.green)),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly payout ready', style: AppText.body(size: 13.5, weight: FontWeight.w800)),
                        Text('₹4,820 · to HDFC ••4471 on Mon', style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                      ],
                    ),
                  ),
                  Text('Details →', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _iconColorForTint(Color tint) {
    if (tint == AppColors.greenPaleBg) return AppColors.green;
    if (tint == AppColors.goldTint) return AppColors.goldDeep;
    return AppColors.accent;
  }

  Widget _statItem(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.display(size: 16, color: Colors.white)),
          Text(label, style: AppText.body(size: 10.5, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
        ],
      );
}
