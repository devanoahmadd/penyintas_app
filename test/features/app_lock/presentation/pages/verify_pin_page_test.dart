import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/verify_pin_page.dart';

class _MockRepo extends Mock implements AppLockRepository {}

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

void main() {
  late AppLocalizations l10n;
  late _MockRepo repo;
  bool? popResult;
  bool popped = false;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    repo = _MockRepo();
    popResult = null;
    popped = false;
    if (sl.isRegistered<AppLockRepository>()) {
      sl.unregister<AppLockRepository>();
    }
    sl.registerFactory<AppLockRepository>(() => repo);
    when(() => repo.getLockedUntilMs()).thenAnswer((_) async => 0);
    when(() => repo.resetFailedAttempts()).thenAnswer((_) async {});
    when(() => repo.recordFailedAttempt()).thenAnswer((_) async {});
  });

  Future<void> pumpAndEnter(WidgetTester tester, List<String> digits) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [_SyncL10nDelegate(l10n)],
        locale: const Locale('id'),
        home: Builder(
          builder: (ctx) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                popResult = await Navigator.of(ctx).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const VerifyPinPage(title: 'Verifikasi'),
                  ),
                );
                popped = true;
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    // Frame kedua wajib — frame pertama baru meng-attach root widget, belum
    // merender tombol "go" (lihat catatan sama di set_pin_page_test.dart).
    await tester.pump();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    for (final d in digits) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('PIN benar → pop(true)', (tester) async {
    when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
    await pumpAndEnter(tester, ['1', '2', '3', '4', '5', '6']);
    expect(popped, isTrue);
    expect(popResult, isTrue);
  });

  testWidgets('PIN salah non-blok → tetap di halaman, pesan salah tampil', (
    tester,
  ) async {
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 2);
    await pumpAndEnter(tester, ['0', '0', '0', '0', '0', '0']);
    expect(popped, isFalse);
    expect(find.text(l10n.applockWrong), findsOneWidget);
  });

  testWidgets('salah tepat blok 5 → recordFailedAttempt + pop(false)', (
    tester,
  ) async {
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 5);
    await pumpAndEnter(tester, ['0', '0', '0', '0', '0', '0']);
    expect(popResult, isFalse);
    verify(() => repo.recordFailedAttempt()).called(1);
  });

  testWidgets(
    'lockout sudah aktif sejak awal → verifyPin tak pernah dipanggil, pop(false)',
    (tester) async {
      when(
        () => repo.getLockedUntilMs(),
      ).thenAnswer((_) async => DateTime.now().millisecondsSinceEpoch + 30000);
      await pumpAndEnter(tester, ['1', '2', '3', '4', '5', '6']);
      verifyNever(() => repo.verifyPin(any()));
      expect(popResult, isFalse);
    },
  );
}
