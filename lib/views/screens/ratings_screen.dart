import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../widgets/common.dart';

class RatingsScreen extends ConsumerWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: Responsive.screenPadding(context, horizontal: 20, vertical: 4).copyWith(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Your ratings', onBack: app.back),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Text('4.9', style: AppText.display(size: 46, height: 1)),
                  const Padding(padding: EdgeInsets.only(top: 6), child: Text('★★★★★', style: TextStyle(color: AppColors.star, fontSize: 19, letterSpacing: 3))),
                  Padding(padding: const EdgeInsets.only(top: 6), child: Text('Based on 1,284 delivered orders', style: AppText.body(size: 12, color: AppColors.bodyGrey))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: ratingBars
                  .map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(width: 26, child: Text('${r.star}★', style: AppText.body(size: 11.5, weight: FontWeight.w700, color: AppColors.bodyGrey))),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(value: r.pct / 100, minHeight: 8, backgroundColor: AppColors.cardBorder, valueColor: const AlwaysStoppedAnimation(AppColors.gold)),
                              ),
                            ),
                            SizedBox(width: 34, child: Text('${r.pct}%', textAlign: TextAlign.right, style: AppText.body(size: 10.5, weight: FontWeight.w600, color: AppColors.lightGreyText))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('What customers say', style: AppText.display(size: 14)),
            const SizedBox(height: 11),
            ...riderReviews.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 34, height: 34, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.plumTint), alignment: Alignment.center, child: Text(r.initials, style: AppText.body(size: 13, weight: FontWeight.w800, color: AppColors.accent))),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: AppText.body(size: 12.5, weight: FontWeight.w700)),
                                Text('★' * r.stars, style: const TextStyle(color: AppColors.star, fontSize: 11, letterSpacing: 1)),
                              ],
                            ),
                          ),
                          Text(r.when, style: AppText.body(size: 11, color: AppColors.lightGreyText)),
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 9), child: Text(r.text, style: AppText.body(size: 12.5, color: AppColors.midGrey, height: 1.5))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
