import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';

class DockNav extends ConsumerWidget {
  const DockNav({super.key});

  static const _tabs = [
    ('home', 'Home', Icons.home_outlined),
    ('history', 'Trips', Icons.receipt_long_outlined),
    ('earnings', 'Earnings', Icons.account_balance_wallet_outlined),
    ('profile', 'Profile', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [BoxShadow(color: AppColors.accentDeep.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.map((t) {
              final active = app.activeTab == t.$1;
              final color = active ? AppColors.accent : AppColors.lightGreyText;
              return Expanded(
                child: GestureDetector(
                  onTap: () => app.tab(t.$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      children: [
                        Icon(t.$3, color: color, size: 23),
                        const SizedBox(height: 3),
                        Text(t.$2, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
