import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';

/// Sumber tunggal untuk icon, color, dan label kategori di presentation layer.
/// Built-in: dari _map statis. Custom: iconSlug dari DB, color selalu primary.
class CategoryMetadata {
  const CategoryMetadata._();

  static const IconData _defaultIcon = Icons.grid_view_outlined;
  static const Color _defaultColor = AppColors.primary;

  /// Resolve (icon, color) dari slug.
  /// Built-in: dari [_map]. Custom: icon dari [iconSlug] via [_iconMap], color primary.
  static (IconData, Color) of(String slug, {String? iconSlug}) {
    if (_map.containsKey(slug)) return _map[slug]!;
    final icon = iconSlug != null ? iconFromSlug(iconSlug) : _defaultIcon;
    return (icon, _defaultColor);
  }

  /// Resolve icon dari slug string yang disimpan DB untuk custom kategori.
  static IconData iconFromSlug(String slug) => _iconMap[slug] ?? _defaultIcon;

  /// Resolve label dari full [CategoryEntity].
  /// Built-in: dari labelKey + l10n. Custom: labelOverride. Fallback: slug.
  static String resolveLabel(CategoryEntity cat, AppLocalizations l10n) {
    if (cat.labelKey != null) return _fromLabelKey(cat.labelKey!, l10n);
    return cat.labelOverride ?? cat.slug;
  }

  /// Resolve label dari slug saja — untuk widget yang hanya punya slug string.
  /// Built-in: dari l10n. Custom slug: slug itu sendiri (fallback, karena labelOverride tidak tersedia).
  static String resolveLabelFromSlug(String slug, AppLocalizations l10n) {
    final key = _slugToLabelKey[slug];
    if (key != null) return _fromLabelKey(key, l10n);
    return slug;
  }

  static String _fromLabelKey(String key, AppLocalizations l10n) => switch (key) {
    'category_food'      => l10n.categoryFood,
    'category_transport' => l10n.categoryTransport,
    'category_shopping'  => l10n.categoryShopping,
    'category_health'    => l10n.categoryHealth,
    'category_internet'  => l10n.categoryInternet,
    'category_other'     => l10n.categoryOther,
    'category_fixed'     => l10n.categoryFixed,
    'category_income'    => l10n.categoryIncome,
    _                    => key,
  };

  static const _slugToLabelKey = <String, String>{
    'food':      'category_food',
    'transport': 'category_transport',
    'shopping':  'category_shopping',
    'health':    'category_health',
    'internet':  'category_internet',
    'other':     'category_other',
    'fixed':     'category_fixed',
    'income':    'category_income',
  };

  // Built-in slug → (icon, color)
  static const _map = <String, (IconData, Color)>{
    'food':      (Icons.restaurant_outlined,     AppColors.warn),
    'transport': (Icons.directions_car_outlined, AppColors.primary),
    'shopping':  (Icons.shopping_bag_outlined,   AppColors.caution),
    'health':    (Icons.favorite_outline,        AppColors.primaryBright),
    'internet':  (Icons.wifi_rounded,            AppColors.primaryDeep),
    'fixed':     (Icons.home_outlined,           AppColors.primary),
    'income':    (Icons.arrow_upward_rounded,    AppColors.primaryBright),
    'other':     (Icons.grid_view_outlined,      AppColors.primary),
  };

  // Icon slug → IconData (untuk custom kategori)
  static const _iconMap = <String, IconData>{
    'restaurant':  Icons.restaurant_outlined,
    'fitness':     Icons.fitness_center_outlined,
    'school':      Icons.school_outlined,
    'pets':        Icons.pets_outlined,
    'travel':      Icons.flight_outlined,
    'gaming':      Icons.sports_esports_outlined,
    'movie':       Icons.movie_outlined,
    'coffee':      Icons.coffee_outlined,
    'pharmacy':    Icons.local_pharmacy_outlined,
    'home':        Icons.home_outlined,
    'sports':      Icons.sports_soccer,
    'book':        Icons.book_outlined,
    'music':       Icons.music_note_outlined,
    'camera':      Icons.photo_camera_outlined,
    'childcare':   Icons.child_care,
    'bar':         Icons.local_bar_outlined,
    'laundry':     Icons.local_laundry_service,
    'bike':        Icons.directions_bike_outlined,
    'wellness':    Icons.self_improvement_outlined,
    'donation':    Icons.volunteer_activism_outlined,
    'cake':        Icons.cake_outlined,
    'repair':      Icons.build_outlined,
    'electronics': Icons.devices_outlined,
    'spa':         Icons.spa_outlined,
    'savings':     Icons.savings_outlined,
  };
}
