import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

// ── Spec constants ─────────────────────────────────────────────────────────
const double _kNavH = 68.0;
const double _kFabDiam = 60.0;
const double _kFabOverhang = 22.0;
const double _kNotchR = 38.0;
const double _kShoulder = 6.0;
const double _kRingGap = 1.0;
const double _kGlowSize = _kFabDiam + 36; // 96 dp
const double _kTabIconSize = 22.0;

// ── Tab definitions ────────────────────────────────────────────────────────
typedef _Tab = ({int id, String label, IconData icon, IconData activeIcon});

const List<_Tab> _kTabs = [
  (
    id: 0,
    label: 'Beranda',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  (
    id: 1,
    label: 'Transaksi',
    icon: Icons.history_outlined,
    activeIcon: Icons.history_rounded,
  ),
  (
    id: 3,
    label: 'Budget',
    icon: Icons.donut_large_outlined,
    activeIcon: Icons.donut_large_rounded,
  ),
  (
    id: 4,
    label: 'Saya',
    icon: Icons.person_outline,
    activeIcon: Icons.person_rounded,
  ),
];

// ── Public widget ──────────────────────────────────────────────────────────

/// Notched edge-to-edge bottom nav bar with embedded FAB.
///
/// Place as [Scaffold.bottomNavigationBar]. Do NOT also set
/// [Scaffold.floatingActionButton] — the FAB is included here.
class AppBottomNavBar extends StatefulWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onFabTap,
  });

  final int currentIndex;
  final VoidCallback onFabTap;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final CurvedAnimation _glowCurve;
  late final AnimationController _sparkleCtrl;
  late final CurvedAnimation _sparkleCurve;
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _glowCurve = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _sparkleCurve = CurvedAnimation(
      parent: _sparkleCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowCurve.dispose();
    _sparkleCurve.dispose();
    _glowCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  void _navigate(BuildContext context, int id) {
    if (id == widget.currentIndex) return;
    switch (id) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/transactions');
      case 3:
        context.go('/budget');
      case 4:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final navH = _kNavH + safeBottom;

    final fillColor = isDark ? const Color(0xFF15301F) : Colors.white;
    final strokeColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final glowColor = isDark
        ? const Color(0x4C6EE7A0)
        : const Color(0x3816A34A);

    return DecoratedBox(
      decoration: isDark
          ? const BoxDecoration()
          : const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x120F2A1C),
                  blurRadius: 16,
                  offset: Offset(0, -6),
                ),
              ],
            ),
      child: SizedBox(
        height: navH,
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowCurve, _sparkleCurve]),
          builder: (context, _) {
            final gV = _glowCurve.value;
            final sV = _sparkleCurve.value;
            final s2V = 1.0 - sV;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _NavNotchPainter(
                      fillColor: fillColor,
                      strokeColor: strokeColor,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(top: 14, bottom: safeBottom),
                    child: Row(
                      children: [
                        _NavTab(
                          icon: _kTabs[0].icon,
                          activeIcon: _kTabs[0].activeIcon,
                          label: _kTabs[0].label,
                          active: widget.currentIndex == _kTabs[0].id,
                          onTap: () => _navigate(context, _kTabs[0].id),
                        ),
                        _NavTab(
                          icon: _kTabs[1].icon,
                          activeIcon: _kTabs[1].activeIcon,
                          label: _kTabs[1].label,
                          active: widget.currentIndex == _kTabs[1].id,
                          onTap: () => _navigate(context, _kTabs[1].id),
                        ),
                        const _FabLabel(),
                        _NavTab(
                          icon: _kTabs[2].icon,
                          activeIcon: _kTabs[2].activeIcon,
                          label: _kTabs[2].label,
                          active: widget.currentIndex == _kTabs[2].id,
                          onTap: () => _navigate(context, _kTabs[2].id),
                        ),
                        _NavTab(
                          icon: _kTabs[3].icon,
                          activeIcon: _kTabs[3].activeIcon,
                          label: _kTabs[3].label,
                          active: widget.currentIndex == _kTabs[3].id,
                          onTap: () => _navigate(context, _kTabs[3].id),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -(_kFabOverhang + 14),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _GlowHalo(
                      glowOpacity: 0.65 + 0.35 * gV,
                      glowScale: 1.0 + 0.06 * gV,
                      glowColor: glowColor,
                    ),
                  ),
                ),
                Positioned(
                  top: -_kFabOverhang,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _PenyFab(
                      sparkleV: sV,
                      sparkle2V: s2V,
                      pressed: _fabPressed,
                      onTapDown: (_) => setState(() => _fabPressed = true),
                      onTap: () {
                        setState(() => _fabPressed = false);
                        widget.onFabTap();
                      },
                      onTapCancel: () => setState(() => _fabPressed = false),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Notch painter ──────────────────────────────────────────────────────────

class _NavNotchPainter extends CustomPainter {
  const _NavNotchPainter({required this.fillColor, required this.strokeColor});

  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_NavNotchPainter old) =>
      old.fillColor != fillColor || old.strokeColor != strokeColor;

  static Path _buildPath(Size size) {
    const double notchR = _kNotchR;
    const double shoulder = _kShoulder;
    final double cx = size.width / 2;
    final double lipX = notchR + shoulder;

    return Path()
      ..moveTo(0, 0)
      ..lineTo(cx - lipX, 0)
      ..quadraticBezierTo(cx - notchR, 0, cx - notchR + 4, 6)
      ..arcToPoint(
        Offset(cx + notchR - 4, 6),
        radius: const Radius.circular(notchR),
        clockwise: false,
      )
      ..quadraticBezierTo(cx + notchR, 0, cx + lipX, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }
}

// ── Glow halo ──────────────────────────────────────────────────────────────

class _GlowHalo extends StatelessWidget {
  const _GlowHalo({
    required this.glowOpacity,
    required this.glowScale,
    required this.glowColor,
  });

  final double glowOpacity;
  final double glowScale;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: glowOpacity,
      child: Transform.scale(
        scale: glowScale,
        child: Container(
          width: _kGlowSize,
          height: _kGlowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [glowColor, Colors.transparent],
              stops: const [0.0, 0.65],
            ),
          ),
        ),
      ),
    );
  }
}

// ── FAB ────────────────────────────────────────────────────────────────────

class _PenyFab extends StatelessWidget {
  const _PenyFab({
    required this.sparkleV,
    required this.sparkle2V,
    required this.pressed,
    required this.onTapDown,
    required this.onTap,
    required this.onTapCancel,
  });

  final double sparkleV;
  final double sparkle2V;
  final bool pressed;
  final GestureTapDownCallback onTapDown;
  final VoidCallback onTap;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final sp1Opacity = 0.75 * (0.35 + 0.60 * sparkleV);
    final sp2Opacity = 0.50 * (0.35 + 0.60 * sparkle2V);
    final sp1Scale = 0.9 + 0.2 * sparkleV;
    final sp2Scale = 0.9 + 0.2 * sparkle2V;

    return GestureDetector(
      onTapDown: onTapDown,
      onTap: onTap,
      onTapCancel: onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: pressed ? 0.96 : 1.0,
        duration: Duration(milliseconds: pressed ? 120 : 180),
        curve: pressed ? Curves.easeOut : Curves.easeIn,
        child: Container(
          width: _kFabDiam,
          height: _kFabDiam,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.36, -0.44),
              radius: 1.0,
              stops: [0.0, 0.45, 1.0],
              colors: [Color(0xFFA8E6B6), Color(0xFF16A34A), Color(0xFF0A5A2D)],
            ),
            border: Border.all(color: scaffoldBg, width: _kRingGap),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F7A3E).withValues(alpha: 0.50),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF0F7A3E).withValues(alpha: 0.30),
                blurRadius: 10,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(Icons.add, color: Colors.white, size: 26),
              ),
              Positioned(
                top: 12,
                left: 16,
                child: Transform.scale(
                  scale: sp1Scale,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: sp1Opacity),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 18,
                right: 14,
                child: Transform.scale(
                  scale: sp2Scale,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: sp2Opacity),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav tab item ───────────────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? AppColors.primary
        : (isDark ? AppColors.mutedDark : AppColors.mutedLight);

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: _kTabIconSize,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    letterSpacing: 0,
                    height: 1.14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── FAB label (center column) ──────────────────────────────────────────────

class _FabLabel extends StatelessWidget {
  const _FabLabel();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: _kFabDiam / 2 + 2),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            'Catat',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0,
              height: 1.14,
            ),
          ),
        ),
      ),
    );
  }
}
