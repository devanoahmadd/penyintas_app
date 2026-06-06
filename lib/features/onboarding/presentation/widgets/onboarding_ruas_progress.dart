import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';

/// Animated progress bar — 3 segments:
/// filled = flex-expanding bar height 6 color primary
/// future = dot width 8 height 8 color border
/// Transitions: width 450ms Cubic(0.2,0.8,0.3,1), bg/height 350ms ease
class OnboardingRuasProgress extends StatelessWidget {
  const OnboardingRuasProgress({
    super.key,
    required this.step,
    this.total = 3,
    required this.isDark,
  });

  final int step;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SizedBox(
      height: 10,
      child: Row(
        children: List.generate(total, (i) {
          final on = i <= step;
          final gap = i < total - 1 ? 6.0 : 0.0;
          if (on) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: gap),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: const Cubic(0.2, 0.8, 0.3, 1.0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.only(right: gap),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.ease,
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }),
      ),
    );
  }
}
