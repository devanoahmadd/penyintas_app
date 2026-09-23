// test/features/settings/challenge_toggle_section_test.dart
//
// Task 17 — sakelar "Tantangan Mingguan" di Pengaturan (T16 di sisi UI).
//
// Diuji lewat widget [ChallengeToggleSection] yang berdiri sendiri — bukan
// lewat SettingsPage penuh — supaya tak perlu menyeret AppDatabase/
// NotificationBloc/SettingsBloc hanya untuk menguji sakelar ini. Meniru
// pola `security_section_test.dart`.
//
// `ChallengeBloc` TIDAK di-provide lewat `BlocProvider` di scope `/settings`
// (lihat `app_router.dart:236-237`) — widget membacanya langsung lewat
// `sl<ChallengeBloc>()`, jadi test mendaftarkan mock ke `sl` (get_it),
// bukan membungkusnya dengan `BlocProvider`.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_bloc.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_event.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_state.dart';
import 'package:penyintas_app/features/settings/presentation/pages/settings_page.dart';

class MockChallengeBloc extends MockBloc<ChallengeEvent, ChallengeState>
    implements ChallengeBloc {}

class _SyncL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncL10nDelegate(this._value);
  final AppLocalizations _value;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _value;
  @override
  bool shouldReload(_) => false;
}

void unregisterAll() {
  if (sl.isRegistered<ChallengeBloc>()) sl.unregister<ChallengeBloc>();
}

ChallengeWeek _buildWeek(ChallengeStatus status) => ChallengeWeek(
  weekKey: 20260921,
  category: 'food',
  targetAmount: 100000,
  baselineAmount: 120000,
  status: status,
  finalSpent: null,
  resolvedAt: null,
  resultSeenAt: null,
);

ChallengeState _stateFor(ChallengePhase phase) => ChallengeState(
  status: ChallengeViewStatus.ready,
  snapshot: ChallengeSnapshot(
    phase: phase,
    pendingResult: null,
    spentThisWeek: 0,
    excludedThisWeek: 0,
    history: const [],
    daysLeft: 5,
  ),
);

void main() {
  late AppLocalizations l10n;
  late MockChallengeBloc bloc;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    bloc = MockChallengeBloc();
    unregisterAll();
    sl.registerLazySingleton<ChallengeBloc>(() => bloc);
  });

  tearDown(unregisterAll);

  void stub(ChallengeState state) {
    whenListen(bloc, Stream<ChallengeState>.value(state), initialState: state);
  }

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [_SyncL10nDelegate(l10n)],
        locale: const Locale('id'),
        home: const Scaffold(body: ChallengeToggleSection()),
      ),
    );
    await tester.pump();
  }

  Finder toggleSwitch() =>
      find.widgetWithText(SwitchListTile, l10n.challengePageTitle);

  testWidgets('phase disabled → switch OFF', (tester) async {
    stub(_stateFor(const PhaseDisabled()));
    await pumpSection(tester);

    expect(find.text(l10n.challengePageTitle.toUpperCase()), findsOneWidget);
    final sw = tester.widget<SwitchListTile>(toggleSwitch());
    expect(sw.value, isFalse);
  });

  testWidgets('phase active → switch ON', (tester) async {
    stub(_stateFor(PhaseActive(week: _buildWeek(ChallengeStatus.active), spent: 0)));
    await pumpSection(tester);

    final sw = tester.widget<SwitchListTile>(toggleSwitch());
    expect(sw.value, isTrue);
  });

  testWidgets('nyalakan dari OFF → langsung dispatch, TANPA dialog', (
    tester,
  ) async {
    stub(_stateFor(const PhaseDisabled()));
    await pumpSection(tester);

    await tester.tap(toggleSwitch());
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    verify(() => bloc.add(const ChallengeEnabledToggled(true))).called(1);
  });

  testWidgets(
    'matikan saat phase active → dialog konfirmasi tampil, batal → TIDAK '
    'dispatch',
    (tester) async {
      stub(_stateFor(PhaseActive(week: _buildWeek(ChallengeStatus.active), spent: 0)));
      await pumpSection(tester);

      await tester.tap(toggleSwitch());
      await tester.pump();

      expect(find.byKey(const Key('challenge-disable-confirm-dialog')), findsOneWidget);
      expect(find.text(l10n.challengeDisableConfirmTitle), findsOneWidget);
      expect(find.text(l10n.challengeDisableConfirmBody), findsOneWidget);

      await tester.tap(find.byKey(const Key('challenge-disable-confirm-cancel')));
      await tester.pumpAndSettle();

      verifyNever(() => bloc.add(const ChallengeEnabledToggled(false)));
    },
  );

  testWidgets(
    'matikan saat phase active → konfirmasi → dispatch ChallengeEnabledToggled(false)',
    (tester) async {
      stub(_stateFor(PhaseActive(week: _buildWeek(ChallengeStatus.active), spent: 0)));
      await pumpSection(tester);

      await tester.tap(toggleSwitch());
      await tester.pump();

      await tester.tap(find.byKey(const Key('challenge-disable-confirm-confirm')));
      await tester.pumpAndSettle();

      verify(() => bloc.add(const ChallengeEnabledToggled(false))).called(1);
    },
  );

  testWidgets(
    'matikan saat phase over → dialog konfirmasi TETAP tampil (minggu masih '
    'berjalan sampai lewat target)',
    (tester) async {
      stub(_stateFor(PhaseOver(week: _buildWeek(ChallengeStatus.active), spent: 150000)));
      await pumpSection(tester);

      await tester.tap(toggleSwitch());
      await tester.pump();

      expect(find.byKey(const Key('challenge-disable-confirm-dialog')), findsOneWidget);
    },
  );

  testWidgets(
    'matikan saat phase held (tidak sedang berjalan) → langsung dispatch, '
    'TANPA dialog',
    (tester) async {
      stub(_stateFor(PhaseHeld(_buildWeek(ChallengeStatus.held))));
      await pumpSection(tester);

      await tester.tap(toggleSwitch());
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
      verify(() => bloc.add(const ChallengeEnabledToggled(false))).called(1);
    },
  );

  testWidgets('dark mode render tanpa error', (tester) async {
    stub(_stateFor(const PhaseDisabled()));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [_SyncL10nDelegate(l10n)],
        locale: const Locale('id'),
        theme: ThemeData.dark(),
        home: const Scaffold(body: ChallengeToggleSection()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
