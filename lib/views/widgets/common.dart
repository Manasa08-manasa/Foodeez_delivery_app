import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Plum-tinted rounded-square back button used on pushed sub-screens
/// (Ratings, Profile→Help). The live Trip screen uses its own back button
/// styles layered over the map/banner instead.
class BackButtonChip extends StatelessWidget {
  final VoidCallback onTap;
  const BackButtonChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.plumTint, border: Border.all(color: AppColors.plumTintBorder, width: 1.5)),
        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.accent),
      ),
    );
  }
}

/// Standard pushed-screen header: back button + title.
class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const ScreenHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          BackButtonChip(onTap: onBack),
          const SizedBox(width: 12),
          Text(title, style: AppText.display(size: 20)),
        ],
      ),
    );
  }
}

/// A pill-style segmented control (Today/Week/Month).
class SegmentedPills extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const SegmentedPills({super.key, required this.labels, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10)] : null,
                ),
                alignment: Alignment.center,
                child: Text(labels[i], style: AppText.body(size: 12.5, weight: FontWeight.w800, color: selected ? AppColors.accent : AppColors.bodyGrey)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The pill on/off switch used on Profile preferences and Home's offline state.
class ToggleSwitch extends StatelessWidget {
  final bool on;
  final VoidCallback? onTap;
  const ToggleSwitch({super.key, required this.on, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 27,
        decoration: BoxDecoration(color: on ? AppColors.green : const Color(0xFFD9CEC6), borderRadius: BorderRadius.circular(20)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))]),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 4-box OTP display, backed by an invisible numeric TextField so tapping
/// opens the OS numeric keypad rather than a custom on-screen one.
class OtpInput extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const OtpInput({super.key, required this.value, required this.onChanged});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(OtpInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(text: widget.value, selection: TextSelection.collapsed(offset: widget.value.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final digit = i < value.length ? value[i] : '';
              final isCursor = i == value.length;
              final filled = digit.isNotEmpty;
              final borderColor = isCursor ? AppColors.accent : (filled ? AppColors.gold : AppColors.otpBorderIdle);
              return Container(
                width: 52,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: 1.5), color: filled ? AppColors.goldTint : Colors.white),
                alignment: Alignment.center,
                child: Text(digit, style: AppText.display(size: 27)),
              );
            }),
          ),
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 260,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
