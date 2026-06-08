import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

// ── applyKey — port dari onb-cplus-atoms.jsx ─────────────────────────────────
int applyOnboardingKey(int current, String key) {
  if (key == 'back') return current ~/ 10;
  if (key == '000') {
    final n = current * 1000;
    return n > 999999999 ? current : n;
  }
  final s = current == 0 ? '' : '$current';
  final n = int.tryParse(s + key) ?? current;
  return n > 999999999 ? current : n;
}

const _kKeys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', 'back'];

class OnboardingKeypad extends StatefulWidget {
  const OnboardingKeypad({
    super.key,
    required this.onKey,
    required this.isDark,
  });

  final void Function(String key) onKey;
  final bool isDark;

  @override
  State<OnboardingKeypad> createState() => _OnboardingKeypadState();
}

class _OnboardingKeypadState extends State<OnboardingKeypad> {
  void _handleTap(String key) {
    HapticFeedback.lightImpact();
    widget.onKey(key);
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = widget.isDark ? AppColors.textDark : AppColors.textLight;
    final textSoft = widget.isDark ? AppColors.textSoftDark : AppColors.textSoftLight;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: _calcAspect(context),
      children: _kKeys.map((key) {
        return _KeyButton(
          keyLabel: key,
          surface: surface,
          textColor: textColor,
          backIconColor: textSoft,
          onTap: () => _handleTap(key),
        );
      }).toList(),
    );
  }

  double _calcAspect(BuildContext context) {
    // Target height = 48dp (Android Material minimum tap target)
    final screenW = MediaQuery.of(context).size.width;
    // Available width = screen minus padding (2×24) minus 2 gaps (7×2)
    final availW = screenW - 48 - 14;
    final colW = availW / 3;
    return colW / 48;
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.keyLabel,
    required this.surface,
    required this.textColor,
    required this.backIconColor,
    required this.onTap,
  });

  final String keyLabel;
  final Color surface;
  final Color textColor;
  final Color backIconColor;
  final VoidCallback onTap;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.ease),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleCtrl.reverse(from: 1.0);
  void _onTapUp(TapUpDetails _) {
    _scaleCtrl.forward();
    widget.onTap();
  }

  void _onTapCancel() => _scaleCtrl.forward();

  @override
  Widget build(BuildContext context) {
    final isBack = widget.keyLabel == 'back';

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Semantics(
          button: true,
          label: widget.keyLabel == 'back' ? 'Hapus' : widget.keyLabel,
          child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: widget.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          alignment: Alignment.center,
          child: isBack
              ? _BackIcon(color: widget.backIconColor)
              : Text(
                  widget.keyLabel,
                  style: AppTextStyles.h3.copyWith(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: widget.keyLabel == '000' ? 16 : 20,
                    fontWeight: FontWeight.w700,
                    color: widget.textColor,
                    height: 1,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _BackIcon extends StatelessWidget {
  const _BackIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _BackIconPainter(color: color),
    );
  }
}

class _BackIconPainter extends CustomPainter {
  const _BackIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Horizontal line: from left-center to right-center
    canvas.drawLine(Offset(cx - 7, cy), Offset(cx + 7, cy), paint);
    // Arrow head pointing left
    canvas.drawLine(Offset(cx - 7, cy), Offset(cx - 1, cy - 6), paint);
    canvas.drawLine(Offset(cx - 7, cy), Offset(cx - 1, cy + 6), paint);
  }

  @override
  bool shouldRepaint(_BackIconPainter old) => old.color != color;
}
