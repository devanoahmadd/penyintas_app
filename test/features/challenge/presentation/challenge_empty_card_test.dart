// Task 15 — enam kartu kosong tantangan mingguan.
//
// Aturan mengikat (spec §7.6/§7.7) yang test ini kunci:
// - `switch` atas `ChallengePhase` TANPA `default` (dijamin compiler, bukan
//   test — tapi test membuktikan SEMUA cabang benar-benar merender sesuatu
//   yang berbeda per phase).
// - Lima dari enam keadaan (`notEnoughData`, `outOfWindow`,
//   `settledThisWeek`, `held`, `budgetNotSet`) SENGAJA tanpa tombol.
// - `disabled` → tepat SATU tombol utama "Nyalakan" 48dp `primary`.
// - Tinggi minimum 120dp di SEMUA keadaan.
// - Latar `card*` (BUKAN `surface*`) — kartu ini permukaan PERMANEN.
// - Nol warna FUNGSIONAL dipakai sebagai warna teks/ikon.
// - Pohon widget TIDAK mengimpor `app_database.dart` (S-C, dikunci di
//   `challenge_result_card_test.dart`).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/presentation/widgets/challenge_empty_card.dart';

/// Delegate sinkron — pola dari `active_challenge_card_test.dart` (Task 14).
class _SyncL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncL10nDelegate(this._value);
  final AppLocalizations _value;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(_value);
  @override
  bool shouldReload(_) => false;
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  ChallengeWeek dummyWeek({ChallengeStatus status = ChallengeStatus.held}) =>
      ChallengeWeek(
        weekKey: 20260907,
        category: null,
        targetAmount: null,
        baselineAmount: null,
        status: status,
        finalSpent: null,
        resolvedAt: null,
        resultSeenAt: null,
      );

  Widget bungkus(Widget child, {bool isDark = false}) => MaterialApp(
    locale: const Locale('id'),
    localizationsDelegates: [_SyncL10nDelegate(l10n)],
    theme: ThemeData(brightness: Brightness.light),
    darkTheme: ThemeData(brightness: Brightness.dark),
    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  Widget kartu(
    ChallengePhase phase, {
    VoidCallback? onEnable,
    bool isDark = false,
  }) => bungkus(
    ChallengeEmptyCard(phase: phase, onEnable: onEnable),
    isDark: isDark,
  );

  void tanpaTombol(String label, ChallengePhase phase) {
    testWidgets('$label → tidak ada tombol sama sekali', (tester) async {
      await tester.pumpWidget(kartu(phase));
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });
  }

  void tinggiMinimum(String label, ChallengePhase phase) {
    testWidgets('$label → tinggi kartu ≥120', (tester) async {
      await tester.pumpWidget(kartu(phase));
      final key = phase is PhaseUndetermined || phase is PhasePreparing
          ? const Key('challenge-empty-card-skeleton')
          : const Key('challenge-empty-card');
      final size = tester.getSize(find.byKey(key));
      expect(size.height, greaterThanOrEqualTo(120));
    });
  }

  // ── disabled · satu tombol utama "Nyalakan" ─────────────────────────────
  group('disabled', () {
    testWidgets('→ tepat satu tombol utama', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled()));
      expect(
        find.byWidgetPredicate((w) => w is ButtonStyleButton),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('challenge-empty-enable-button')),
        findsOneWidget,
      );
    });

    testWidgets('→ tombol Nyalakan ≥48dp', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled()));
      final size = tester.getSize(
        find.byKey(const Key('challenge-empty-enable-button')),
      );
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('→ tap tombol memanggil onEnable', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        kartu(const PhaseDisabled(), onEnable: () => tapped = true),
      );
      await tester.tap(find.byKey(const Key('challenge-empty-enable-button')));
      expect(tapped, isTrue);
    });

    testWidgets('→ judul & body sesuai copy', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled()));
      expect(find.text(l10n.challengeEmptyDisabledTitle), findsOneWidget);
      expect(find.text(l10n.challengeEmptyDisabledBody), findsOneWidget);
    });

    tinggiMinimum('disabled', const PhaseDisabled());
  });

  // ── notEnoughData ────────────────────────────────────────────────────────
  group('notEnoughData', () {
    testWidgets('→ judul & body sesuai copy', (tester) async {
      await tester.pumpWidget(kartu(const PhaseNotEnoughData()));
      expect(find.text(l10n.challengeEmptyNotEnoughDataTitle), findsOneWidget);
      expect(find.text(l10n.challengeEmptyNotEnoughDataBody), findsOneWidget);
    });

    tanpaTombol('notEnoughData', const PhaseNotEnoughData());
    tinggiMinimum('notEnoughData', const PhaseNotEnoughData());
  });

  // ── outOfWindow (isFirstWeek true/false) ────────────────────────────────
  group('outOfWindow · isFirstWeek true', () {
    testWidgets('→ judul & body pertama kali', (tester) async {
      await tester.pumpWidget(kartu(const PhaseOutOfWindow(isFirstWeek: true)));
      expect(
        find.text(l10n.challengeEmptyOutOfWindowFirstTitle),
        findsOneWidget,
      );
      expect(
        find.text(l10n.challengeEmptyOutOfWindowFirstBody),
        findsOneWidget,
      );
    });

    tanpaTombol(
      'outOfWindow(isFirstWeek: true)',
      const PhaseOutOfWindow(isFirstWeek: true),
    );
    tinggiMinimum(
      'outOfWindow(isFirstWeek: true)',
      const PhaseOutOfWindow(isFirstWeek: true),
    );
  });

  group('outOfWindow · isFirstWeek false', () {
    testWidgets('→ judul & body reguler', (tester) async {
      await tester.pumpWidget(
        kartu(const PhaseOutOfWindow(isFirstWeek: false)),
      );
      expect(find.text(l10n.challengeEmptyOutOfWindowTitle), findsOneWidget);
      expect(find.text(l10n.challengeEmptyOutOfWindowBody), findsOneWidget);
    });

    tanpaTombol(
      'outOfWindow(isFirstWeek: false)',
      const PhaseOutOfWindow(isFirstWeek: false),
    );
    tinggiMinimum(
      'outOfWindow(isFirstWeek: false)',
      const PhaseOutOfWindow(isFirstWeek: false),
    );
  });

  // ── settledThisWeek ──────────────────────────────────────────────────────
  group('settledThisWeek', () {
    testWidgets('→ judul & body sesuai copy', (tester) async {
      await tester.pumpWidget(kartu(PhaseSettledThisWeek(dummyWeek())));
      expect(find.text(l10n.challengeEmptySettledTitle), findsOneWidget);
      expect(find.text(l10n.challengeEmptySettledBody), findsOneWidget);
    });

    tanpaTombol('settledThisWeek', PhaseSettledThisWeek(dummyWeek()));
    tinggiMinimum('settledThisWeek', PhaseSettledThisWeek(dummyWeek()));
  });

  // ── held ─────────────────────────────────────────────────────────────────
  group('held', () {
    testWidgets('→ judul & body sesuai copy', (tester) async {
      await tester.pumpWidget(kartu(PhaseHeld(dummyWeek())));
      expect(find.text(l10n.challengeEmptyHeldTitle), findsOneWidget);
      expect(find.text(l10n.challengeEmptyHeldBody), findsOneWidget);
    });

    tanpaTombol('held', PhaseHeld(dummyWeek()));
    tinggiMinimum('held', PhaseHeld(dummyWeek()));
  });

  // ── budgetNotSet ─────────────────────────────────────────────────────────
  group('budgetNotSet', () {
    testWidgets('→ judul & body sesuai copy', (tester) async {
      await tester.pumpWidget(kartu(const PhaseBudgetNotSet()));
      expect(find.text(l10n.challengeEmptyBudgetNotSetTitle), findsOneWidget);
      expect(find.text(l10n.challengeEmptyBudgetNotSetBody), findsOneWidget);
    });

    tanpaTombol('budgetNotSet', const PhaseBudgetNotSet());
    tinggiMinimum('budgetNotSet', const PhaseBudgetNotSet());
  });

  // ── undetermined/preparing · skeleton ────────────────────────────────────
  group('undetermined/preparing · skeleton', () {
    testWidgets('undetermined → skeleton tampil, tanpa teks judul/body', (
      tester,
    ) async {
      await tester.pumpWidget(kartu(const PhaseUndetermined()));
      expect(
        find.byKey(const Key('challenge-empty-card-skeleton')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('challenge-empty-title')), findsNothing);
    });

    testWidgets('preparing → skeleton tampil, tanpa teks judul/body', (
      tester,
    ) async {
      await tester.pumpWidget(kartu(const PhasePreparing()));
      expect(
        find.byKey(const Key('challenge-empty-card-skeleton')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('challenge-empty-title')), findsNothing);
    });

    tanpaTombol('undetermined', const PhaseUndetermined());
    tanpaTombol('preparing', const PhasePreparing());
    tinggiMinimum('undetermined', const PhaseUndetermined());
    tinggiMinimum('preparing', const PhasePreparing());
  });

  // ── PhaseActive/PhaseOver · bukan tanggung jawab kartu ini ──────────────
  group('PhaseActive/PhaseOver · ditolak, bukan dirender kosong', () {
    ChallengeWeek activeWeek() => ChallengeWeek(
      weekKey: 20260907,
      category: 'food',
      targetAmount: 100000,
      baselineAmount: 130000,
      status: ChallengeStatus.active,
      finalSpent: null,
      resolvedAt: null,
      resultSeenAt: null,
    );

    testWidgets('PhaseActive → melempar ArgumentError', (tester) async {
      await tester.pumpWidget(
        kartu(PhaseActive(week: activeWeek(), spent: 10000)),
      );
      expect(tester.takeException(), isArgumentError);
    });

    testWidgets('PhaseOver → melempar ArgumentError', (tester) async {
      await tester.pumpWidget(
        kartu(PhaseOver(week: activeWeek(), spent: 150000)),
      );
      expect(tester.takeException(), isArgumentError);
    });
  });

  // ── Warna · judul text*, body & ikon textSoft*, nol fungsional ─────────
  group('Warna · judul text*, body & ikon textSoft*', () {
    testWidgets('tema terang · judul textLight', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled()));
      final t = tester.widget<Text>(
        find.byKey(const Key('challenge-empty-title')),
      );
      expect(t.style?.color, AppColors.textLight);
    });

    testWidgets('tema gelap · judul textDark', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled(), isDark: true));
      final t = tester.widget<Text>(
        find.byKey(const Key('challenge-empty-title')),
      );
      expect(t.style?.color, AppColors.textDark);
    });

    testWidgets('tema terang · body textSoftLight', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled()));
      final t = tester.widget<Text>(
        find.byKey(const Key('challenge-empty-body')),
      );
      expect(t.style?.color, AppColors.textSoftLight);
    });

    testWidgets('tema gelap · body textSoftDark', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled(), isDark: true));
      final t = tester.widget<Text>(
        find.byKey(const Key('challenge-empty-body')),
      );
      expect(t.style?.color, AppColors.textSoftDark);
    });

    testWidgets('tema terang · ikon textSoftLight', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled()));
      final icon = tester.widget<Icon>(
        find.byKey(const Key('challenge-empty-icon')),
      );
      expect(icon.color, AppColors.textSoftLight);
    });

    testWidgets('tema gelap · ikon textSoftDark', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled(), isDark: true));
      final icon = tester.widget<Icon>(
        find.byKey(const Key('challenge-empty-icon')),
      );
      expect(icon.color, AppColors.textSoftDark);
    });

    testWidgets(
      'nol Text/Icon (selain teks tombol Nyalakan) memakai warna fungsional',
      (tester) async {
        await tester.pumpWidget(kartu(const PhaseDisabled()));
        const terlarang = [
          AppColors.warn,
          AppColors.caution,
          AppColors.primaryBright,
          AppColors.success,
        ];
        for (final t in tester.widgetList<Text>(find.byType(Text))) {
          expect(
            terlarang,
            isNot(contains(t.style?.color)),
            reason: 'Text "${t.data}" memakai warna fungsional',
          );
        }
        for (final i in tester.widgetList<Icon>(find.byType(Icon))) {
          expect(
            terlarang,
            isNot(contains(i.color)),
            reason: 'Icon ${i.icon} memakai warna fungsional',
          );
        }
      },
    );
  });

  // ── Latar · card*, BUKAN surface* ───────────────────────────────────────
  group('Latar · card*, bukan surface*', () {
    testWidgets('tema terang → cardLight', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled()));
      final container = tester.widget<Container>(
        find.byKey(const Key('challenge-empty-card')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.cardLight);
      expect(decoration.color, isNot(AppColors.surfaceLight));
    });

    testWidgets('tema gelap → cardDark', (tester) async {
      await tester.pumpWidget(kartu(const PhaseDisabled(), isDark: true));
      final container = tester.widget<Container>(
        find.byKey(const Key('challenge-empty-card')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.cardDark);
      expect(decoration.color, isNot(AppColors.surfaceDark));
    });
  });
}
