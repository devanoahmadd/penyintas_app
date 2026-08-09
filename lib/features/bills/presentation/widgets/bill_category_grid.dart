import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';

/// Grid pemilih kategori untuk form tagihan (spec §5.3, keputusan D2 & D9).
///
/// Menerima daftar MENTAH dari `CategoryLoaded`, lalu menyaring dan
/// mengurutkan sendiri. Penyaringan `income` sengaja tinggal di sini supaya
/// invariant I6 punya satu rumah yang bisa diuji, bukan tersebar ke pemanggil.
///
/// PEMANGGIL WAJIB memastikan `categories` datang dari `CategoryLoaded`.
/// Mengirim daftar kosong karena bloc masih memuat akan membuat kategori
/// terpilih terlihat seperti kategori yang sudah dihapus — lihat aturan tile
/// yatim di bawah.
class BillCategoryGrid extends StatelessWidget {
  const BillCategoryGrid({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<CategoryEntity> categories;
  final String? selectedSlug;
  final ValueChanged<String> onSelected;

  /// Tinggi satu tile. TETAP, bukan turunan lebar — lihat catatan
  /// `mainAxisExtent` di bawah. Dipakai juga oleh placeholder di
  /// `bill_form_page.dart` untuk memesan ruang yang sama persis.
  static const double tinggiTile = 76;

  /// Jumlah kolom. Dipakai placeholder untuk menghitung tinggi cadangannya.
  static const int jumlahKolom = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // I6: tagihan SELALU pengeluaran. Memilih kategori pemasukan akan
    // mengotori laporan saat tandai-lunas mencatat transaksi. Dulu dijamin
    // daftar `const`; kini diturunkan dari data — jaminannya identik.
    //
    // `fixed` DIPAKSA ke depan [Audit T3]. Daftar `const` lama
    // (`kBillCategorySlugs`) menaruhnya di posisi PERTAMA, dan itu bukan
    // kebetulan: tagihan di aplikasi ini adalah kos, listrik, cicilan.
    // `sortOrder` di DB (food 0 · transport 1 · shopping 2 · health 3 ·
    // internet 4 · other 5 · fixed 6) melayani layar Transaksi & Anggaran,
    // tempat 'fixed' memang jarang dipakai. Mengikutinya mentah-mentah di
    // sini akan menurunkan 'fixed' ke BARIS KETIGA grid, di bawah "Lainnya" —
    // membuang urutan yang selama ini sudah benar untuk layar ini, dan
    // menyulitkan jalur I2 (memilih 'fixed' menyalakan toggle kebutuhan
    // tetap).
    //
    // Yang dipaksa hanya SATU slug dan hanya di widget ini. Seed DB tidak
    // disentuh — ia milik bersama layar lain.
    final hidup = categories.where((c) => c.type == 'expense').toList()
      ..sort((a, b) {
        if (a.slug == b.slug) return 0;
        if (a.slug == 'fixed') return -1;
        if (b.slug == 'fixed') return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    // D9 — kategori yatim: slug terpilih yang kategorinya sudah dihapus.
    //
    // `hidup.isNotEmpty` BUKAN kelengkapan gaya. Daftar kosong berarti bloc
    // belum selesai memuat (atau gagal), dan memperlakukannya sebagai
    // "kategori terhapus" membuat SETIAP tagihan yang dibuka untuk diedit
    // menampilkan tile yatim. Pemanggil sudah dijaga di sisi bloc; ini lapis
    // kedua supaya widget ini aman dipakai sendiri.
    final adaDiDaftar = hidup.any((c) => c.slug == selectedSlug);
    final yatim = selectedSlug != null && hidup.isNotEmpty && !adaDiDaftar
        ? selectedSlug!
        : null;

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // `mainAxisExtent`, BUKAN `childAspectRatio` [Audit S9].
      //
      // Rasio 1.0 membuat tile PERSEGI: di ponsel 360dp dengan padding form
      // 16×2, tiap tile jadi 104×104. Untuk ikon 22dp + label dua baris itu
      // kotak kosong yang sangat besar, dan grid sendirian memakan sepertiga
      // halaman yang sudah berisi sembilan kontrol. Rasio juga membuat
      // `minHeight: 64` di tile jadi mati total — tingginya sudah dipaksa
      // dari lebar.
      //
      // Tinggi tetap membuat tile melebar mengikuti layar tapi tak pernah
      // menjulang, dan membuat asersi "tiap tile minimal 64dp" bermakna di
      // viewport test mana pun.
      //
      // Jarak antar-tile `AppSpacing.sm` (8) memenuhi ambang `touch-spacing`
      // (minimum 8dp antar area tap) — gerbang ui-ux-pro-max §2.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: jumlahKolom,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisExtent: tinggiTile,
      ),
      children: [
        for (final cat in hidup)
          _CategoryTile(
            label: CategoryMetadata.resolveLabel(cat, l10n),
            // `of()` — BUKAN `iconFromSlug()`. Slug kategori built-in ada di
            // `_map`, sedangkan `iconFromSlug` melihat namespace ikon KUSTOM
            // (`restaurant`/`coffee`/…), sehingga semua kategori jatuh ke
            // ikon grid generik. Ini pernah jadi bug sungguhan.
            icon: CategoryMetadata.of(cat.slug, iconSlug: cat.iconSlug).$1,
            selected: cat.slug == selectedSlug,
            isDark: isDark,
            onTap: () => onSelected(cat.slug),
          ),
        if (yatim != null)
          _CategoryTile(
            // Nama cantiknya (`labelOverride`) ikut terhapus bersama
            // kategorinya dan TAK BISA dipulihkan — bill hanya menyimpan slug.
            // `prettifySlug` adalah yang terbaik yang bisa diperbuat dari
            // bahan yang tersisa.
            label: CategoryMetadata.prettifySlug(yatim),
            icon: Icons.grid_view_outlined,
            selected: true,
            isDark: isDark,
            onTap: () => onSelected(yatim),
          ),
      ],
    );
  }
}

/// Satu tile kategori.
///
/// ── Keadaan terpilih (gerbang ui-ux-pro-max) ───────────────────────────────
///
/// Rancangan awal membedakan terpilih hanya lewat WARNA border (+ tebal 2dp).
/// Gerbang menolaknya karena dua aturan:
///
///  • `color-not-only` (severity HIGH) — beda 1dp pada ketebalan garis nyaris
///    tak terbaca; kalau hue dicabut, tile terpilih dan tak terpilih praktis
///    identik. Isi permukaan yang solid memberi beda LUMINANSI besar, yang
///    tetap terbaca tanpa persepsi warna sama sekali.
///  • `consistency` (severity HIGH) — empat baris `_ChoicePill` di form yang
///    sama (pengulangan, tenor, pengingat) sudah memakai isi solid
///    `AppColors.primary` + teks putih untuk "terpilih". Grid beroutline
///    membuat satu layar berbicara dua bahasa untuk konsep yang sama.
///
/// Jadi pembedanya kini tiga lapis: isi permukaan, bobot huruf, dan bendera
/// `Semantics.selected` untuk pembaca layar.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Panel input pakai token khusus panel — sejalan dengan field lain di
    // form ini (lihat CLAUDE.md: surfaceAltLight/Dark).
    final panelColor = isDark
        ? AppColors.surfaceAltDark
        : AppColors.surfaceAltLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final fg = selected ? Colors.white : textColor;

    // SENGAJA tanpa `label:` — teks di dalam tile sudah menyumbang labelnya,
    // dan menuliskannya lagi di sini membuat pembaca layar mengucapkan nama
    // kategori DUA KALI ("Makan & Minum, Makan & Minum").
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : panelColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? AppColors.primary : borderColor,
              ),
            ),
            child: Container(
              // Hit target minimum Android 48dp terlampaui jauh; 64 adalah
              // lantai supaya ikon + label dua baris tetap lega.
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: fg),
                  const SizedBox(height: AppSpacing.xs),
                  // `Flexible` supaya label yang memanjang karena penskalaan
                  // teks sistem terpotong rapi, bukan meluber dari tile yang
                  // tingginya sengaja tetap.
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        // 12 mengikuti tangga ukuran yang sudah dipakai form
                        // ini (13 label · 12 catatan) — bukan ukuran baru.
                        fontSize: 12,
                        height: 1.2,
                        color: fg,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
