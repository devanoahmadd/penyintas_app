import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';

/// Growing bamboo shoot widget.
/// grow ∈ [0,1] drives stem height, leaf count, and color.
/// 300ms ease transition when grow changes.
class GrowShoot extends StatefulWidget {
  const GrowShoot({
    super.key,
    required this.grow,
    this.size = 108,
    required this.isDark,
  });

  final double grow;
  final double size;
  final bool isDark;

  @override
  State<GrowShoot> createState() => _GrowShootState();
}

class _GrowShootState extends State<GrowShoot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _growAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _growAnim = AlwaysStoppedAnimation(widget.grow.clamp(0.0, 1.0));
  }

  @override
  void didUpdateWidget(GrowShoot old) {
    super.didUpdateWidget(old);
    if (old.grow != widget.grow) {
      final from = _growAnim.value;
      _growAnim = Tween<double>(
        begin: from,
        end: widget.grow.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.ease));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.cardDark : AppColors.cardLight;
    final soilColor = widget.isDark ? AppColors.soilDark : AppColors.soilLight;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final g = _growAnim.value.clamp(0.0, 1.0);
        final stemH = (16 + g * (widget.size - 30)).roundToDouble();
        final stemColor = g >= 0.8
            ? AppColors.primaryBright
            : AppColors.primary;

        return SizedBox(
          width: 78,
          height: widget.size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: ColoredBox(
              color: surface,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // soil strip
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(height: 14, color: soilColor),
                  ),
                  // stem
                  Positioned(
                    bottom: 12,
                    left: 78 / 2 - 3,
                    child: Container(
                      width: 6,
                      height: stemH,
                      decoration: BoxDecoration(
                        color: stemColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // leaf 1 — pucuk, always bright, dir=right
                  _Leaf(
                    stemH: stemH,
                    offset: 9,
                    dir: 1,
                    scale: 1.0,
                    color: AppColors.primaryBright,
                  ),
                  // leaf 2 — dir=left
                  _Leaf(
                    stemH: stemH,
                    offset: 22,
                    dir: -1,
                    scale: 0.95,
                    color: stemColor,
                  ),
                  // leaf 3 — g >= 0.45, dir=right
                  if (g >= 0.45)
                    _Leaf(
                      stemH: stemH,
                      offset: 36,
                      dir: 1,
                      scale: 0.85,
                      color: stemColor,
                    ),
                  // leaf 4 — g >= 0.75, dir=left
                  if (g >= 0.75)
                    _Leaf(
                      stemH: stemH,
                      offset: 50,
                      dir: -1,
                      scale: 0.78,
                      color: stemColor,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Leaf extends StatelessWidget {
  const _Leaf({
    required this.stemH,
    required this.offset,
    required this.dir,
    required this.scale,
    required this.color,
  });

  final double stemH;
  final double offset;
  final int dir; // 1 = right, -1 = left
  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final w = 20 * scale;
    final h = 12 * scale;
    final bottom = 12 + stemH - offset;
    // CSS: left '50%', translateX(-2px) for right, translateX(-90%) for left
    final left = dir > 0 ? (78 / 2 - 2) : (78 / 2 - w * 0.9);
    final angleDeg = dir > 0 ? -22.0 : 22.0;
    final borderRadius = dir > 0
        ? const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          );

    return Positioned(
      bottom: bottom,
      left: left,
      child: Transform.rotate(
        angle: angleDeg * math.pi / 180,
        alignment: Alignment.center,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: color, borderRadius: borderRadius),
        ),
      ),
    );
  }
}
