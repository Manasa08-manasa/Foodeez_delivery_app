import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/app_models.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';

class IncomingRequestAlert extends ConsumerStatefulWidget {
  const IncomingRequestAlert({super.key});

  @override
  ConsumerState<IncomingRequestAlert> createState() => _IncomingRequestAlertState();
}

class _IncomingRequestAlertState extends ConsumerState<IncomingRequestAlert> with SingleTickerProviderStateMixin {
  late final AnimationController _bell = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _bell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final req = app.activeRequest ?? demoRequest;
    final cod = req.paymentMethod == PaymentMethod.cod;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: AnimatedBuilder(
                  animation: _bell,
                  builder: (context, _) {
                    final t = _bell.value;
                    final ring = (t * 5).floor() % 5;
                    const angles = [0.0, -0.24, 0.21, -0.14, 0.1];
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: (1 - t).clamp(0, 1) * 0.25,
                          child: Transform.scale(scale: 0.7 + t * 1.3, child: Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green))),
                        ),
                        Transform.rotate(
                          angle: angles[ring],
                          child: Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green), alignment: Alignment.center, child: const Icon(Icons.inventory_2_outlined, size: 26, color: Colors.white)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text('New delivery request', style: AppText.display(size: 20)),
              Padding(padding: const EdgeInsets.only(top: 2), child: Text('Respond in ${app.alertCountdown}s', style: AppText.body(size: 12.5, color: AppColors.bodyGrey))),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stat('+₹${req.payout}', 'payout', AppColors.green),
                    _divider(),
                    _stat('${req.totalKm}', 'km total', AppColors.ink),
                    _divider(),
                    _stat('${req.totalMins}', 'min', AppColors.ink),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Column(
                        children: [
                          Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accent, width: 2))),
                          Container(width: 2, height: 22, color: AppColors.dividerBorder),
                          Container(width: 9, height: 9, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${req.restaurantName} · ${req.restaurantAddress.split(',').first}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12.5, weight: FontWeight.w700)),
                          Padding(padding: const EdgeInsets.only(top: 12), child: Text('${req.customerAddress} · ${req.totalKm} km', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12.5, weight: FontWeight.w700))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(color: cod ? AppColors.goldTint : AppColors.greenPaleBg, borderRadius: BorderRadius.circular(9)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cod) ...[
                        const Icon(Icons.payments_outlined, size: 13, color: AppColors.goldDeep),
                        const SizedBox(width: 5),
                      ],
                      Text(cod ? 'Collect ₹${req.orderTotal} in cash' : '✓ Prepaid · ${paymentMethodLabel(req.paymentMethod)}', style: AppText.body(size: 11, weight: FontWeight.w800, color: cod ? AppColors.goldDeep : AppColors.green)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: app.rejectAlert,
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEAD9D9), width: 1.5), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Text('Decline', style: AppText.body(size: 14, weight: FontWeight.w800, color: AppColors.red)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: app.acceptAlert,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Text('Accept delivery', style: AppText.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Column(
        children: [
          Text(value, style: AppText.display(size: 22, color: color)),
          Text(label, style: AppText.body(size: 10.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
        ],
      );

  Widget _divider() => Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 13), color: AppColors.dividerBorder2);
}
