import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

/// Shared bottom nav bar used across all main tab pages.
/// Handles routing internally; caller only provides [currentIndex] and [onFabTap].
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onFabTap,
  });

  final int currentIndex;
  final VoidCallback onFabTap;

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/transactions');
      case 3:
      case 4:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fitur ini segera hadir.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: bgColor,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: l10n.navHome,
                active: currentIndex == 0,
                onTap: () => _onTap(context, 0),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.dehaze_rounded,
                activeIcon: Icons.dehaze_rounded,
                label: l10n.navTransactions,
                active: currentIndex == 1,
                onTap: () => _onTap(context, 1),
                isDark: isDark,
              ),
              const Expanded(child: SizedBox()),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: l10n.navBudget,
                active: currentIndex == 3,
                onTap: () => _onTap(context, 3),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: l10n.navProfile,
                active: currentIndex == 4,
                onTap: () => _onTap(context, 4),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FAB widget — 64px outer ring + 56px primary circle + "Catat" label.
/// Place as [Scaffold.floatingActionButton] with
/// [FloatingActionButtonLocation.centerDocked].
class AppNavFab extends StatelessWidget {
  const AppNavFab({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark ? AppColors.surfaceDark : Colors.white;
    final outlineColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ringColor,
              shape: BoxShape.circle,
              border: Border.all(color: outlineColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x330F7A3E),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catat',
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.primary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : (isDark ? AppColors.mutedDark : AppColors.mutedLight);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: color,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
