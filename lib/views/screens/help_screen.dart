import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.read(appControllerProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Help & support', onBack: app.back),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppColors.sosGradient, border: Border.all(color: const Color(0xFFEFCFCF), width: 1.5), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(14)), alignment: Alignment.center, child: const Icon(Icons.sos_outlined, size: 22, color: Colors.white)),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency SOS', style: AppText.display(size: 14, color: const Color(0xFF8A1E1E))),
                        Text('Shares your live location with our safety team', style: AppText.body(size: 11.5, color: const Color(0xFFA85252))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Common questions', style: AppText.display(size: 14)),
            const SizedBox(height: 11),
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: supportFaqs
                    .map((q) => Container(
                          padding: const EdgeInsets.all(15),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                          child: Row(
                            children: [
                              Expanded(child: Text(q, style: AppText.body(size: 13, weight: FontWeight.w700))),
                              const Text('→', style: TextStyle(color: AppColors.lightGreyText)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Reach us', style: AppText.display(size: 14)),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(child: _reachCard(Icons.call_outlined, 'Call support', '24×7 rider line')),
                const SizedBox(width: 12),
                Expanded(child: _reachCard(Icons.chat_bubble_outline, 'Live chat', 'Avg reply 2 min')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reachCard(IconData icon, String title, String sub) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.accent),
            Padding(padding: const EdgeInsets.only(top: 6), child: Text(title, style: AppText.body(size: 12.5, weight: FontWeight.w800))),
            Padding(padding: const EdgeInsets.only(top: 1), child: Text(sub, style: AppText.body(size: 10.5, color: AppColors.bodyGrey))),
          ],
        ),
      );
}
