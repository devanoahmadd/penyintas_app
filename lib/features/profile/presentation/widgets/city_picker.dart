// lib/features/profile/presentation/widgets/city_picker.dart
//
// CityPicker — bottom-sheet pilih kota (discoped by country).
//
// Dirancang via ui-ux-pro-max:
//   • Bottom-sheet surface = surfaceAlt*
//   • Sudut atas = AppRadius.lg
//   • Search field dengan key('city_search')
//   • Tiap baris menampilkan TimezoneCity.label ("Kota · GMT+X")
//   • Tap kota → Navigator.pop(context, city) — String nama kota
//   • Escape-hatch (B-2): baris key('city_pick_tz_direct') SELALU tampil
//     paling bawah; jika citiesIn kosong → hanya baris ini yang ada.
//     Tap → buka sheet zona langsung (search key: 'tz_direct_search').
//     Tap zona langsung → Navigator.pop(context, TimezonePick(iana)).
//   • Dark-mode responsif. Hit target ≥ 48dp. TANPA emoji.

import 'package:flutter/material.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';

// ────────────────────────────────────────────────────────────────
// Tipe hasil — dibedakan oleh caller (ProfileLegPage / B4):
//   String   → nama kota (setCurrentCity)
//   TimezonePick → zona IANA langsung (setTimezone, city kosong)
// ────────────────────────────────────────────────────────────────

/// Hasil dari CityPicker saat user memilih zona waktu langsung
/// (escape-hatch B-2). Caller membedakan: `String` = kota,
/// `TimezonePick` = zona IANA tanpa kota.
class TimezonePick {
  const TimezonePick(this.iana);
  final String iana;

  @override
  bool operator ==(Object other) =>
      other is TimezonePick && other.iana == iana;

  @override
  int get hashCode => iana.hashCode;

  @override
  String toString() => 'TimezonePick($iana)';
}

// ────────────────────────────────────────────────────────────────
// Helper: tampilkan CityPicker sebagai bottom-sheet
// ────────────────────────────────────────────────────────────────

/// Tampilkan CityPicker sebagai modal bottom-sheet.
///
/// Returns:
///   - `String` — nama kota yang dipilih
///   - `TimezonePick` — bila user memilih zona langsung via escape-hatch
///   - `null` — bila dibatalkan
Future<dynamic> showCityPicker(
  BuildContext context, {
  required String country,
  required TimezoneResolver resolver,
}) {
  return showModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CityPicker(country: country, resolver: resolver),
  );
}

// ────────────────────────────────────────────────────────────────
// CityPicker widget
// ────────────────────────────────────────────────────────────────

/// Bottom-sheet pilih kota, discoped by [country].
///
/// Menampilkan kota dari [resolver.citiesIn(country)].
/// Baris terakhir SELALU escape-hatch [Key('city_pick_tz_direct')].
/// Jika tidak ada kota → hanya escape-hatch yang ditampilkan.
class CityPicker extends StatefulWidget {
  const CityPicker({
    super.key,
    required this.country,
    required this.resolver,
  });

  final String country;
  final TimezoneResolver resolver;

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  final _searchCtrl = TextEditingController();
  late final List<TimezoneCity> _allCities;
  List<TimezoneCity> _filtered = [];

  @override
  void initState() {
    super.initState();
    _allCities = widget.resolver.citiesIn(widget.country);
    _filtered = List.of(_allCities);
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.of(_allCities);
      } else {
        _filtered = _allCities
            .where((c) => c.city.toLowerCase().contains(query))
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
    final sheetBg =
        isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoft = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final hasNoCities = _allCities.isEmpty;

    // Gunakan Material sebagai root agar ListTile dapat surface yang benar
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
            // ── Handle ─────────────────────────────────────────
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

            // ── Judul ───────────────────────────────────────────
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
                    'Pilih Kota',
                    style: AppTextStyles.h3.copyWith(color: textColor),
                  ),
                  const Spacer(),
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

            // ── Search field (disembunyikan bila tidak ada kota) ─
            if (!hasNoCities) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  key: const Key('city_search'),
                  controller: _searchCtrl,
                  style: AppTextStyles.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Cari kota...',
                    hintStyle:
                        AppTextStyles.bodySmall.copyWith(color: mutedColor),
                    prefixIcon:
                        Icon(Icons.search, color: mutedColor, size: 20),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.cardDark : AppColors.cardLight,
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
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],

            // ── Divider ─────────────────────────────────────────
            Divider(height: 1, color: borderColor),

            // ── Konten daftar ───────────────────────────────────
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                children: [
                  // Pesan saat negara tidak ada kota di dataset
                  if (hasNoCities)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        'Kota belum tersedia untuk negara ini.\nPilih zona waktu langsung di bawah.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: mutedColor),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Daftar kota (bila ada & tidak di-filter habis)
                  if (!hasNoCities) ...[
                    if (_filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'Kota tidak ditemukan.',
                          style:
                              AppTextStyles.body.copyWith(color: mutedColor),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._filtered.map(
                        (city) => _CityRow(
                          label: city.label,
                          textColor: textColor,
                          textSoft: textSoft,
                          borderColor: borderColor,
                          onTap: () =>
                              Navigator.of(context).pop(city.city),
                        ),
                      ),
                  ],

                  // ── Escape-hatch (B-2) — SELALU tampil paling bawah ──
                  _EscapeHatchRow(
                    textColor: textColor,
                    textSoft: textSoft,
                    borderColor: borderColor,
                    mutedColor: mutedColor,
                    onTap: () => _openTzDirectSheet(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sheet zona langsung ──────────────────────────────────────

  Future<void> _openTzDirectSheet(BuildContext context) async {
    final result = await showModalBottomSheet<TimezonePick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TzDirectSheet(resolver: widget.resolver),
    );
    if (result != null && context.mounted) {
      Navigator.of(context).pop(result);
    }
  }
}

// ────────────────────────────────────────────────────────────────
// Row item kota
// ────────────────────────────────────────────────────────────────

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.label,
    required this.textColor,
    required this.textSoft,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
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
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(color: textColor),
      ),
      trailing: Icon(Icons.chevron_right, color: textSoft, size: 18),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Escape-hatch row — Key('city_pick_tz_direct')
// ────────────────────────────────────────────────────────────────

class _EscapeHatchRow extends StatelessWidget {
  const _EscapeHatchRow({
    required this.textColor,
    required this.textSoft,
    required this.borderColor,
    required this.mutedColor,
    required this.onTap,
  });

  final Color textColor;
  final Color textSoft;
  final Color borderColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: borderColor),
        ListTile(
          key: const Key('city_pick_tz_direct'),
          onTap: onTap,
          minTileHeight: 56,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xs,
          ),
          leading: const Icon(
            Icons.public_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          title: Text(
            'Pilih zona waktu langsung',
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
          subtitle: Text(
            'Untuk kota yang belum terdaftar',
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
          ),
          trailing: Icon(Icons.chevron_right, color: textSoft, size: 18),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Sheet "Pilih zona waktu langsung" — _TzDirectSheet
// ────────────────────────────────────────────────────────────────

class _TzDirectSheet extends StatefulWidget {
  const _TzDirectSheet({required this.resolver});
  final TimezoneResolver resolver;

  @override
  State<_TzDirectSheet> createState() => _TzDirectSheetState();
}

class _TzDirectSheetState extends State<_TzDirectSheet> {
  final _searchCtrl = TextEditingController();
  late final List<TimezoneCity> _allZones;
  List<TimezoneCity> _filtered = [];

  @override
  void initState() {
    super.initState();
    _allZones = widget.resolver.distinctZones();
    _filtered = List.of(_allZones);
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.of(_allZones);
      } else {
        _filtered = _allZones
            .where((z) =>
                z.label.toLowerCase().contains(query) ||
                z.iana.toLowerCase().contains(query))
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
    final sheetBg =
        isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoft = isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

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
            // Handle
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

            // Judul
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
                    'Pilih Zona Waktu',
                    style: AppTextStyles.h3.copyWith(color: textColor),
                  ),
                  const Spacer(),
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

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: TextField(
                key: const Key('tz_direct_search'),
                controller: _searchCtrl,
                style: AppTextStyles.body.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Cari zona waktu...',
                  hintStyle:
                      AppTextStyles.bodySmall.copyWith(color: mutedColor),
                  prefixIcon:
                      Icon(Icons.search, color: mutedColor, size: 20),
                  filled: true,
                  fillColor:
                      isDark ? AppColors.cardDark : AppColors.cardLight,
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
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),

            Divider(height: 1, color: borderColor),

            // Daftar zona
            Flexible(
              child: _filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'Zona waktu tidak ditemukan.',
                          style:
                              AppTextStyles.body.copyWith(color: mutedColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemExtent: 56,
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.xxxl),
                      itemBuilder: (ctx, i) {
                        final zone = _filtered[i];
                        return ListTile(
                          minTileHeight: 56,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.xs,
                          ),
                          title: Text(
                            zone.label,
                            style: AppTextStyles.body
                                .copyWith(color: textColor),
                          ),
                          subtitle: Text(
                            zone.iana,
                            style: AppTextStyles.caption
                                .copyWith(color: mutedColor),
                          ),
                          trailing: Icon(Icons.chevron_right,
                              color: textSoft, size: 18),
                          onTap: () => Navigator.of(context)
                              .pop(TimezonePick(zone.iana)),
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
