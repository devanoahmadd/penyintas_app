import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/widgets/common/fixed_need_toggle_tile.dart';

void main() {
  Widget harness({
    bool value = false,
    bool enabled = true,
    VoidCallback? onHelpTap,
    ValueChanged<bool>? onChanged,
  }) => MaterialApp(
    home: Scaffold(
      body: FixedNeedToggleTile(
        tileKey: const ValueKey('tile'),
        switchKey: const ValueKey('sw'),
        value: value,
        label: 'Termasuk kebutuhan tetap?',
        hint: 'Disisihkan lebih dulu.',
        panelColor: AppColors.surfaceAltLight,
        borderColor: AppColors.borderLight,
        textColor: AppColors.textLight,
        mutedColor: AppColors.mutedLight,
        enabled: enabled,
        onHelpTap: onHelpTap,
        helpSemanticLabel: 'Apa itu kebutuhan tetap?',
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );

  testWidgets('menampilkan label dan hint', (tester) async {
    await tester.pumpWidget(harness());
    expect(find.text('Termasuk kebutuhan tetap?'), findsOneWidget);
    expect(find.text('Disisihkan lebih dulu.'), findsOneWidget);
  });

  testWidgets('tanpa onHelpTap, tombol bantuan TIDAK digambar', (tester) async {
    await tester.pumpWidget(harness());
    expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
  });

  testWidgets('dengan onHelpTap, tombol bantuan muncul dan bisa ditekan', (
    tester,
  ) async {
    var ditekan = 0;
    await tester.pumpWidget(harness(onHelpTap: () => ditekan++));
    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pump();
    expect(ditekan, 1);
  });

  testWidgets('menekan tombol bantuan TIDAK ikut membalik toggle', (
    tester,
  ) async {
    bool? nilaiBaru;
    await tester.pumpWidget(
      harness(onHelpTap: () {}, onChanged: (v) => nilaiBaru = v),
    );
    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pump();
    expect(nilaiBaru, isNull);
  });

  // ── [Audit B1] Penjaga a11y — inti dari restrukturisasi ────────────────
  //
  // Test di ATAS (tap tak membalik toggle) tetap HIJAU meski tombol berada di
  // dalam MergeSemantics, karena arena gestur memenangkan recognizer terdalam.
  // Test ini yang membedakan keduanya: ia bertanya apakah tombol punya NODE
  // SEMANTIK sendiri — satu-satunya hal yang menentukan pengguna pembaca layar
  // bisa menjangkaunya atau tidak.
  testWidgets('tombol bantuan punya node semantik SENDIRI — tak termerge '
      'ke dalam tile', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(onHelpTap: () {}));

    final node = tester.getSemantics(find.byIcon(Icons.help_outline_rounded));

    expect(node.label, 'Apa itu kebutuhan tetap?');
    expect(
      // `hasFlag(SemanticsFlag.isButton)` deprecated sejak v3.32.0 —
      // `flagsCollection.isButton` adalah penggantinya, sama-sama `bool`.
      node.flagsCollection.isButton,
      isTrue,
      reason: 'ikon tanpa peran tombol tak bisa diaktifkan pembaca layar',
    );
    expect(
      node.label,
      isNot(contains('Termasuk kebutuhan tetap?')),
      reason: 'label tile ikut terbaca = tombol sudah tertelan MergeSemantics',
    );

    handle.dispose();
  });

  testWidgets('tile TETAP satu node — label, hint, dan switch bersuara '
      'bersama', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(onHelpTap: () {}));

    final node = tester.getSemantics(find.byKey(const ValueKey('sw')));

    expect(node.label, contains('Termasuk kebutuhan tetap?'));
    expect(
      node.label,
      contains('Disisihkan lebih dulu.'),
      reason:
          'merge label+hint+switch adalah keputusan a11y yang dipertahankan',
    );

    handle.dispose();
  });

  testWidgets('tombol bantuan memenuhi hit target 48dp', (tester) async {
    await tester.pumpWidget(harness(onHelpTap: () {}));
    final size = tester.getSize(
      find
          .ancestor(
            of: find.byIcon(Icons.help_outline_rounded),
            matching: find.byType(InkResponse),
          )
          .first,
    );
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('enabled=false membuat Switch tak bisa diubah', (tester) async {
    bool? nilaiBaru;
    await tester.pumpWidget(
      harness(enabled: false, onChanged: (v) => nilaiBaru = v),
    );
    await tester.tap(find.byKey(const ValueKey('tile')));
    await tester.pump();
    expect(nilaiBaru, isNull);
  });

  // ── Task 15: risiko tercatat sejak Task 2 — tombol (?) tanpa label
  // semantik tak terbaca sama sekali oleh pembaca layar, dan tak ada apa pun
  // yang menangkapnya. `assert` ini menegakkan kontrak dartdoc di atas.
  test('assert: helpSemanticLabel wajib diisi kalau onHelpTap non-null', () {
    expect(
      () => FixedNeedToggleTile(
        tileKey: const ValueKey('t'),
        switchKey: const ValueKey('s'),
        value: false,
        label: 'Termasuk kebutuhan tetap?',
        hint: 'Disisihkan lebih dulu.',
        panelColor: AppColors.surfaceAltLight,
        borderColor: AppColors.borderLight,
        textColor: AppColors.textLight,
        mutedColor: AppColors.mutedLight,
        onChanged: (_) {},
        onHelpTap: () {},
        // helpSemanticLabel SENGAJA tidak diisi.
      ),
      throwsAssertionError,
    );
  });

  test(
    'tanpa onHelpTap, helpSemanticLabel boleh null (tak melanggar assert)',
    () {
      expect(
        () => FixedNeedToggleTile(
          tileKey: const ValueKey('t'),
          switchKey: const ValueKey('s'),
          value: false,
          label: 'Termasuk kebutuhan tetap?',
          hint: 'Disisihkan lebih dulu.',
          panelColor: AppColors.surfaceAltLight,
          borderColor: AppColors.borderLight,
          textColor: AppColors.textLight,
          mutedColor: AppColors.mutedLight,
          onChanged: (_) {},
        ),
        returnsNormally,
      );
    },
  );
}
