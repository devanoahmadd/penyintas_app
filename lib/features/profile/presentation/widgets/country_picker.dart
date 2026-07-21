// lib/features/profile/presentation/widgets/country_picker.dart
//
// CountryPicker — bottom-sheet pilih negara (onboarding profil).
//
// Dirancang via ui-ux-pro-max:
//   • Bottom-sheet surface = surfaceAlt* (bukan Colors.white)
//   • Sudut atas = AppRadius.lg
//   • Search field dengan key('country_search')
//   • Tap baris → Navigator.pop(context, kodeAlpha2)
//   • TANPA flag emoji (N2)
//   • Dark-mode responsif via Theme.of(context).brightness
//   • Hit target ≥ 48dp setiap baris (ListTile min height)
//   • Spacing AppSpacing.*, radius AppRadius.*

import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';

// ────────────────────────────────────────────────────────────────
// Dataset negara (alpha-2 → nama Bahasa Indonesia)
// Cakupan: 19 negara wajib dari dataset timezone + destinasi
// perantau umum. Diurutkan alfabetis nama.
// ────────────────────────────────────────────────────────────────
const Map<String, String> _kCountryNames = {
  'AF': 'Afghanistan',
  'ZA': 'Afrika Selatan',
  'DZ': 'Aljazair',
  'US': 'Amerika Serikat',
  'SA': 'Arab Saudi',
  'AU': 'Australia',
  'NL': 'Belanda',
  'BR': 'Brasil',
  'CN': 'Cina',
  'FR': 'Prancis',
  'DE': 'Jerman',
  'HK': 'Hong Kong',
  'IN': 'India',
  'ID': 'Indonesia',
  'GB': 'Inggris',
  'IT': 'Italia',
  'JP': 'Jepang',
  'KH': 'Kamboja',
  'CA': 'Kanada',
  'KR': 'Korea Selatan',
  'KW': 'Kuwait',
  'MY': 'Malaysia',
  'EG': 'Mesir',
  'MX': 'Meksiko',
  'NZ': 'Selandia Baru',
  'PK': 'Pakistan',
  'PH': 'Filipina',
  'PT': 'Portugal',
  'QA': 'Qatar',
  'RU': 'Rusia',
  'SG': 'Singapura',
  'ES': 'Spanyol',
  'LK': 'Sri Lanka',
  'CH': 'Swiss',
  'TW': 'Taiwan',
  'TH': 'Thailand',
  'TR': 'Turki',
  'AE': 'Uni Emirat Arab',
  'VN': 'Vietnam',
};

// Sorted by nama (value), built lazily once
List<MapEntry<String, String>> _sortedCountries() {
  final entries = _kCountryNames.entries.toList();
  entries.sort((a, b) => a.value.compareTo(b.value));
  return entries;
}

// ────────────────────────────────────────────────────────────────
// Helper: tampilkan CountryPicker sebagai bottom-sheet
// ────────────────────────────────────────────────────────────────

/// Tampilkan CountryPicker sebagai modal bottom-sheet.
///
/// Returns: kode alpha-2 (String) atau null bila dibatalkan.
Future<String?> showCountryPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CountryPicker(),
  );
}

// ────────────────────────────────────────────────────────────────
// CountryPicker widget
// ────────────────────────────────────────────────────────────────

/// Bottom-sheet pilih negara (alpha-2 code → nama Indonesia).
///
/// Dipakai di ProfileLegPage (B4) via [showCountryPicker].
/// Tap baris → [Navigator.pop] dengan kode alpha-2.
class CountryPicker extends StatefulWidget {
  const CountryPicker({super.key});

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  final _searchCtrl = TextEditingController();
  final _allCountries = _sortedCountries();
  List<MapEntry<String, String>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.of(_allCountries);
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.of(_allCountries);
      } else {
        _filtered = _allCountries
            .where(
              (e) =>
                  e.value.toLowerCase().contains(query) ||
                  e.key.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark
        ? AppColors.surfaceAltDark
        : AppColors.surfaceAltLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoft = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    // Gunakan Material sebagai root agar ListTile mendapat surface yang benar
    return Material(
      color: sheetBg,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),

            // ── Judul ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Pilih Negara',
                    style: AppTextStyles.h3.copyWith(color: textColor),
                  ),
                  const Spacer(),
                  // Tombol tutup — hit target 48dp
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: Icon(Icons.close, color: mutedColor, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Tutup',
                    ),
                  ),
                ],
              ),
            ),

            // ── Search field ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: TextField(
                key: const Key('country_search'),
                controller: _searchCtrl,
                style: AppTextStyles.body.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Cari negara...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: mutedColor,
                  ),
                  prefixIcon: Icon(Icons.search, color: mutedColor, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: borderColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // ── Divider ───────────────────────────────────────────
            Divider(height: 1, color: borderColor),

            // ── Daftar negara ─────────────────────────────────────
            Flexible(
              child: _filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'Negara tidak ditemukan.',
                          style: AppTextStyles.body.copyWith(color: mutedColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemExtent: 56, // Hit target ≥ 48dp
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                      itemBuilder: (ctx, i) {
                        final entry = _filtered[i];
                        return _CountryRow(
                          code: entry.key,
                          name: entry.value,
                          textColor: textColor,
                          textSoft: textSoft,
                          borderColor: borderColor,
                          onTap: () => Navigator.of(context).pop(entry.key),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Row item negara
// ────────────────────────────────────────────────────────────────

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.code,
    required this.name,
    required this.textColor,
    required this.textSoft,
    required this.borderColor,
    required this.onTap,
  });

  final String code;
  final String name;
  final Color textColor;
  final Color textSoft;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      leading: SizedBox(
        width: 36,
        child: Text(
          code,
          style: AppTextStyles.caption.copyWith(color: textSoft),
        ),
      ),
      title: Text(
        name,
        style: AppTextStyles.body.copyWith(color: textColor),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.chevron_right, color: textSoft, size: 18),
    );
  }
}
