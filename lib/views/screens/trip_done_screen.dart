import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';

class TripDoneScreen extends ConsumerWidget {
  const TripDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    final req = app.activeRequest ?? demoRequest;
    final total = basePay + tipPay;

    return Container(
      decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.1, colors: [AppColors.greenPaleBg2, Colors.white], stops: [0, 0.6])),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.green, boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.6), blurRadius: 34, offset: const Offset(0, 18))]),
                  child: const Icon(Icons.check, color: Colors.white, size: 46),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Delivered!', style: AppText.display(size: 25)),
                    const SizedBox(width: 8),
                    const Icon(Icons.celebration_outlined, size: 24, color: AppColors.green),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Great job, $riderName. Order #${req.orderId} handed over to ${req.customerName.split(' ').first}.', textAlign: TextAlign.center, style: AppText.body(size: 13.5, color: AppColors.bodyGrey, height: 1.5)),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.dividerBorder2), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _row('Trip payout', '₹$basePay', AppColors.ink),
                      _row('Customer tip', '+₹$tipPay', AppColors.green),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('You earned', style: AppText.display(size: 14)),
                            Text('₹$total', style: AppText.display(size: 22, color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: ElevatedButton(
                        onPressed: app.toHome,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Text('Back online', style: AppText.body(size: 15, weight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF4EFEB)))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
            Text(value, style: AppText.body(size: 14, weight: FontWeight.w800, color: color)),
          ],
        ),
      );
}
