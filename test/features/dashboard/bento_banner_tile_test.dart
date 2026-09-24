import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/dashboard/presentation/widgets/bento_banner_tile.dart';

/// Butir 4 (keputusan pemilik repo 2026-09-24) — tile bento selebar penuh
/// berbentuk BANNER horizontal, bukan `BentoFeatTile` vertikal yang dipaksa
/// melebar (⅔ ruang kanan kosong, hijau di grid ≈57%).
void main() {
  Widget pasang({
    String badge = 'Mingguan',
    String sub = 'Makan & Minum · sisa Rp 82.000',
    double lebar = 360,
    double skalaTeks = 1,
    VoidCallback? onTap,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(lebar, 800),
        textScaler: TextScaler.linear(skalaTeks),
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: lebar,
            child: BentoBannerTile(
              bg: AppColors.primary,
              icon: Icons.flag_outlined,
              label: 'Tantangan',
              sub: sub,
              badge: badge,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('merender label, sub, dan badge dalam satu baris', (
    tester,
  ) async {
    await tester.pumpWidget(pasang());
    expect(find.text('Tantangan'), findsOneWidget);
    expect(find.text('Makan & Minum · sisa Rp 82.000'), findsOneWidget);
    expect(find.text('Mingguan'), findsOneWidget);

    // Horizontal: ikon di KIRI label, badge di KANAN label.
    final ikon = tester.getCenter(find.byIcon(Icons.flag_outlined));
    final label = tester.getCenter(find.text('Tantangan'));
    final badge = tester.getCenter(find.text('Mingguan'));
    expect(ikon.dx, lessThan(label.dx));
    expect(badge.dx, greaterThan(label.dx));
  });

  testWidgets('badge kosong → pill TIDAK dirender', (tester) async {
    await tester.pumpWidget(pasang(badge: ''));
    expect(find.byKey(const Key('bento-banner-badge')), findsNothing);
  });

  testWidgets('tinggi pendek (banner, bukan kartu 116) tapi >= 48dp', (
    tester,
  ) async {
    await tester.pumpWidget(pasang());
    final ukuran = tester.getSize(find.byType(BentoBannerTile));
    expect(ukuran.height, kBentoBannerMinHeight);
    expect(ukuran.height, lessThan(116));
    expect(ukuran.height, greaterThanOrEqualTo(48));
    expect(ukuran.width, 360);
  });

  testWidgets('ketuk memanggil onTap', (tester) async {
    var diketuk = 0;
    await tester.pumpWidget(pasang(onTap: () => diketuk++));
    await tester.tap(find.byType(BentoBannerTile));
    expect(diketuk, 1);
  });

  testWidgets('font 2x di HP sempit (320dp): tumbuh ke bawah, NOL overflow, '
      'sub tidak dipotong jadi satu baris', (tester) async {
    await tester.pumpWidget(pasang(lebar: 320, skalaTeks: 2));
    expect(tester.takeException(), isNull);
    final ukuran = tester.getSize(find.byType(BentoBannerTile));
    expect(ukuran.height, greaterThan(kBentoBannerMinHeight));
    final sub = tester.widget<Text>(
      find.text('Makan & Minum · sisa Rp 82.000'),
    );
    expect(sub.maxLines, greaterThan(1));
  });
}
