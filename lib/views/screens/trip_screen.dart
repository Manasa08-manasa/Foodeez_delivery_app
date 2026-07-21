import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/mock_data.dart';
import '../../models/app_models.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../widgets/common.dart';
import '../widgets/faux_map.dart';

class _StageInfo {
  final String badge;
  final String title;
  final String sub;
  final IconData icon;
  final Color iconBg;
  final String navEta;
  final String navDist;
  final bool arrived;
  final bool showItems;
  final bool showHandover;
  final String actionLabel;
  final String navUrl;
  final String arrivedTitle;

  const _StageInfo({
    required this.badge,
    required this.title,
    required this.sub,
    required this.icon,
    required this.iconBg,
    required this.navEta,
    required this.navDist,
    required this.arrived,
    required this.showItems,
    required this.showHandover,
    required this.actionLabel,
    required this.navUrl,
    required this.arrivedTitle,
  });

  bool get enroute => !arrived;
}

_StageInfo _infoFor(DeliveryStage stage, DeliveryRequest req) {
  String mapsUrl(String destination) => 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=driving';

  switch (stage) {
    case DeliveryStage.toPickup:
      return _StageInfo(
        badge: 'HEAD TO PICKUP', title: req.restaurantName, sub: req.restaurantAddress, icon: Icons.restaurant_outlined, iconBg: AppColors.goldTint,
        navEta: '4 min', navDist: '1.2 km', arrived: false, showItems: false, showHandover: false,
        actionLabel: "I've reached the restaurant", navUrl: mapsUrl('${req.restaurantName}, ${req.restaurantAddress}'), arrivedTitle: '',
      );
    case DeliveryStage.atPickup:
      return _StageInfo(
        badge: 'COLLECT ORDER', title: req.restaurantName, sub: "Show rider code · Ask for order #${req.orderId}", icon: Icons.restaurant_outlined, iconBg: AppColors.goldTint,
        navEta: '', navDist: '', arrived: true, showItems: true, showHandover: false,
        actionLabel: 'Order picked up', navUrl: '', arrivedTitle: "You're at the restaurant",
      );
    case DeliveryStage.toDrop:
      return _StageInfo(
        badge: 'DELIVER TO', title: req.customerName, sub: req.customerAddress, icon: Icons.location_on_outlined, iconBg: AppColors.plumTint,
        navEta: '11 min', navDist: '3.2 km', arrived: false, showItems: false, showHandover: false,
        actionLabel: "I've reached the drop", navUrl: mapsUrl('${req.customerName}, ${req.customerAddress}'), arrivedTitle: '',
      );
    case DeliveryStage.atDrop:
      return _StageInfo(
        badge: 'HAND OVER', title: req.customerName, sub: req.customerAddress, icon: Icons.location_on_outlined, iconBg: AppColors.plumTint,
        navEta: '', navDist: '', arrived: true, showItems: false, showHandover: true,
        actionLabel: 'Complete delivery', navUrl: '', arrivedTitle: "You're at the drop",
      );
  }
}

class TripScreen extends ConsumerWidget {
  const TripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final req = app.activeRequest ?? demoRequest;
    final info = _infoFor(app.stage, req);
    final cod = req.paymentMethod == PaymentMethod.cod;
    final showOtp = app.stage == DeliveryStage.atPickup || app.stage == DeliveryStage.atDrop;
    final showCod = app.stage == DeliveryStage.atDrop && cod;
    final showPaid = app.stage == DeliveryStage.atDrop && !cod;
    final otpTitle = app.stage == DeliveryStage.atPickup ? 'Enter pickup OTP' : 'Enter delivery OTP';
    final otpHint = app.stage == DeliveryStage.atPickup ? "Shown on the restaurant's partner dashboard" : 'Ask ${req.customerName.split(' ').first} for the 4-digit code';
    final otpDoneLabel = app.stage == DeliveryStage.atPickup ? 'Pickup verified' : 'Delivery verified';
    final actionReady = app.actionReady;

    return Column(
      children: [
        if (info.enroute)
          SizedBox(
            height: 378,
            child: Stack(
              children: [
                Positioned.fill(child: FauxMap(destinationIcon: info.icon)),
                Positioned(
                  top: 58,
                  left: 18,
                  child: GestureDetector(
                    onTap: app.back,
                    child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]), child: const Icon(Icons.arrow_back_ios_new, size: 18)),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 10))]),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(info.navEta, style: AppText.display(size: 15, color: Colors.white)),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 15, color: Colors.white.withValues(alpha: 0.25)),
                          const SizedBox(width: 10),
                          Text(info.navDist, style: AppText.body(size: 12.5, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse(info.navUrl), mode: LaunchMode.externalApplication),
                    child: Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent, boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(0, 8))]), child: const Icon(Icons.navigation, color: Colors.white, size: 20)),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            height: 130,
            padding: Responsive.screenPadding(context, horizontal: 20).copyWith(top: 54),
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: app.back,
                  child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(9)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('●', style: TextStyle(color: AppColors.greenDotBright, fontSize: 10)),
                          const SizedBox(width: 6),
                          Text('Arrived', style: AppText.body(size: 10.5, weight: FontWeight.w800, color: Colors.white)),
                        ]),
                      ),
                      Padding(padding: const EdgeInsets.only(top: 6), child: Text(info.arrivedTitle, style: AppText.display(size: 18, color: Colors.white))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            width: double.infinity,
            transform: Matrix4.translationValues(0, -24, 0),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
            child: SingleChildScrollView(
              padding: Responsive.screenPadding(context, horizontal: 20, vertical: 8).copyWith(bottom: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: AppColors.dividerBorder, borderRadius: BorderRadius.circular(3)))),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.plumTint, borderRadius: BorderRadius.circular(8)), child: Text(info.badge, style: AppText.body(size: 10.5, weight: FontWeight.w800, color: AppColors.accent, letterSpacing: 0.6))),
                      const SizedBox(width: 8),
                      Text('Order #${req.orderId}', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey)),
                      const Spacer(),
                      Text('Earn +₹${req.payout}', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.green)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 42, height: 42, decoration: BoxDecoration(color: info.iconBg, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Icon(info.icon, size: 21, color: info.iconBg == AppColors.goldTint ? AppColors.goldDeep : AppColors.accent)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(info.title, style: AppText.display(size: 16)),
                                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(info.sub, style: AppText.body(size: 12.5, color: AppColors.bodyGrey))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 13),
                          child: Row(
                            children: [
                              Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.call, size: 15), label: Text('Call', style: AppText.body(size: 13, weight: FontWeight.w800)), style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.dividerBorder, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                              const SizedBox(width: 10),
                              Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline, size: 15), label: Text('Chat', style: AppText.body(size: 13, weight: FontWeight.w800)), style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.dividerBorder, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showOtp) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFDF7), Colors.white]), border: Border.all(color: AppColors.goldTintBorder2, width: 1.5), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Text(otpTitle, textAlign: TextAlign.center, style: AppText.display(size: 16)),
                          Padding(padding: const EdgeInsets.only(top: 3), child: Text(otpHint, textAlign: TextAlign.center, style: AppText.body(size: 11.5, color: AppColors.bodyGrey))),
                          Padding(padding: const EdgeInsets.only(top: 14), child: OtpInput(value: app.activeOtp, onChanged: app.setOtp)),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: app.otpDone
                                ? Text('✓ $otpDoneLabel', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.green))
                                : Text('Tap the boxes to enter the code', style: AppText.body(size: 11, weight: FontWeight.w600, color: AppColors.lightGreyText)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (info.showItems) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verify the order', style: AppText.body(size: 13, weight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          ...req.items.map((l) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.5),
                                child: Row(
                                  children: [
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 8), height: 24, constraints: const BoxConstraints(minWidth: 26), decoration: BoxDecoration(color: AppColors.plumTint, borderRadius: BorderRadius.circular(7)), alignment: Alignment.center, child: Text('${l.qty}×', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.accent))),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(l.name, style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.midGrey2))),
                                  ],
                                ),
                              )),
                          Container(
                            margin: const EdgeInsets.only(top: 11),
                            padding: const EdgeInsets.only(top: 11),
                            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.dividerBorder2, style: BorderStyle.solid))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Packed & sealed by restaurant', style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.bodyGrey)),
                                Text('₹${req.orderTotal}', style: AppText.body(size: 12.5, weight: FontWeight.w800, color: AppColors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (showCod) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: app.toggleCod,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                        decoration: BoxDecoration(color: app.codCollected ? AppColors.greenPaleBg2 : Colors.white, border: Border.all(color: app.codCollected ? AppColors.greenPaleBorder2 : AppColors.dividerBorder2, width: 1.5), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: app.codCollected ? AppColors.green : const Color(0xFFD9CEC6), width: 2), color: app.codCollected ? AppColors.green : Colors.transparent),
                              alignment: Alignment.center,
                              child: app.codCollected ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Collect ₹${req.orderTotal} in cash', style: AppText.body(size: 13.5, weight: FontWeight.w800)),
                                  Text(app.codCollected ? 'Cash received' : 'Tap once you have the cash', style: AppText.body(size: 11.5, color: AppColors.bodyGrey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (showPaid) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                      decoration: BoxDecoration(color: AppColors.greenPaleBg2, border: Border.all(color: AppColors.greenPaleBorder, width: 1.5), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(11)), alignment: Alignment.center, child: Icon(paymentMethodIcon(req.paymentMethod), size: 18, color: Colors.white)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Prepaid · nothing to collect', style: AppText.body(size: 13.5, weight: FontWeight.w800)),
                                Text('₹${req.orderTotal} paid online via ${paymentMethodLabel(req.paymentMethod)}', style: AppText.body(size: 11.5, color: AppColors.greenMutedText)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check, color: AppColors.green, size: 18),
                        ],
                      ),
                    ),
                  ],
                  if (info.enroute) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(info.navUrl), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.navigation, size: 17),
                        label: Text('Navigate in Google Maps', style: AppText.body(size: 14.5, weight: FontWeight.w800, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: actionReady ? app.nextStage : null,
                      style: ElevatedButton.styleFrom(backgroundColor: actionReady ? AppColors.green : const Color(0xFFB9D8C3), disabledBackgroundColor: const Color(0xFFB9D8C3), padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: Text(info.actionLabel, style: AppText.body(size: 15, weight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: GestureDetector(onTap: app.toHelp, child: Text('Need help with this order?', style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.bodyGrey))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
