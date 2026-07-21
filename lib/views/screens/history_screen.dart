import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appControllerProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trip history', style: AppText.display(size: 20)),
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text('$todayTrips trips today · ${moneyFmt(todayEarn)} earned', style: AppText.body(size: 12.5, color: AppColors.bodyGrey))),
                ],
              ),
            ),
            ...tripHistory.map((h) {
              final tagFg = h.delivered ? AppColors.green : AppColors.goldDeep;
              final tagBg = h.delivered ? AppColors.greenPaleBg : AppColors.goldTint;
              return Container(
                margin: const EdgeInsets.only(bottom: 11),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('#${h.id}', style: AppText.body(size: 12.5, weight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(7)), child: Text(h.delivered ? 'DELIVERED' : 'CANCELLED', style: AppText.body(size: 10.5, weight: FontWeight.w700, color: tagFg))),
                        const Spacer(),
                        Text(h.pay != null ? '+₹${h.pay}' : '—', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.green)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Column(
                              children: [
                                Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accent, width: 2))),
                                Container(width: 2, height: 20, color: AppColors.dividerBorder),
                                Container(width: 9, height: 9, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.from, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.midGrey2)),
                                Padding(padding: const EdgeInsets.only(top: 9), child: Text(h.to, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.midGrey2))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 11),
                      padding: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.dividerBorder2, style: BorderStyle.solid))),
                      child: Row(
                        children: [
                          Text(h.when, style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                          const SizedBox(width: 10),
                          Text('·', style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                          const SizedBox(width: 10),
                          Text('${h.km} km', style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                          const Spacer(),
                          Text(h.stars != null ? '${h.stars!.toStringAsFixed(1)} ★' : '—', style: AppText.body(size: 11.5, weight: FontWeight.w800, color: AppColors.star)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
