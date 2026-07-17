import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/verify_pin_page.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_keypad.dart';

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

  Future<void> pumpAndOpen(WidgetTester tester) async {
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
  }

  Future<void> pumpAndEnter(WidgetTester tester, List<String> digits) async {
    await pumpAndOpen(tester);
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

  testWidgets(
    'salah tepat blok 5 → recordFailedAttempt + countdown tampil di tempat '
    '(halaman TIDAK menutup diri)',
    (tester) async {
      when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
      when(() => repo.getFailedAttempts()).thenAnswer((_) async => 5);
      // Meniru app_lock_repository_impl.dart. Dua panggilan PERTAMA belum
      // lockout: (1) _syncLockout() saat initState halaman dibuka, (2) cek
      // awal di verifyPinWithLockout saat submit (sebelum attempt ke-5
      // tercatat). Panggilan BERIKUTNYA (_syncLockout lagi, dipicu outcome
      // lockedOut setelah recordFailedAttempt mencapai kelipatan 5) sudah
      // lockout.
      var callCount = 0;
      when(() => repo.getLockedUntilMs()).thenAnswer((_) async {
        callCount++;
        return callCount <= 2
            ? 0
            : DateTime.now().millisecondsSinceEpoch + 30000;
      });
      await pumpAndEnter(tester, ['0', '0', '0', '0', '0', '0']);

      // Halaman TIDAK menutup diri — beda dari perilaku lama (pop(false)).
      expect(popped, isFalse);
      verify(() => repo.recordFailedAttempt()).called(1);

      // Countdown tampil DI TEMPAT — cocokkan bentuk pesannya (bukan angka
      // detik persis, karena ceil() bisa 29/30 tergantung timing eksekusi
      // test) lewat getter resmi applockLockedWait, pola sama seperti
      // lock_screen_test.dart.
      final countdownPattern = RegExp(
        RegExp.escape(l10n.applockLockedWait(999)).replaceAll('999', r'\d+'),
      );
      expect(find.textContaining(countdownPattern), findsOneWidget);

      // Keypad harus nonaktif selama lockout.
      final keypad = tester.widget<PinKeypad>(find.byType(PinKeypad));
      expect(keypad.enabled, isFalse);
    },
  );

  testWidgets(
    'masuk halaman saat lockout SUDAH AKTIF → countdown & keypad disabled '
    'LANGSUNG tampil TANPA perlu submit PIN dulu',
    (tester) async {
      when(
        () => repo.getLockedUntilMs(),
      ).thenAnswer((_) async => DateTime.now().millisecondsSinceEpoch + 30000);
      await pumpAndOpen(tester);

      // Belum mengetik satu digit pun — countdown & keypad disabled harus
      // sudah tampil sejak initState, meniru bug device: masuk ulang ke
      // halaman saat lockout aktif harus langsung terlihat, bukan baru
      // muncul sekejap saat submit.
      final countdownPattern = RegExp(
        RegExp.escape(l10n.applockLockedWait(999)).replaceAll('999', r'\d+'),
      );
      expect(find.textContaining(countdownPattern), findsOneWidget);
      final keypad = tester.widget<PinKeypad>(find.byType(PinKeypad));
      expect(keypad.enabled, isFalse);

      // Pertahanan berlapis — tap digit selama lockout tak boleh memicu
      // verifikasi PIN sama sekali (guard `onDigit` + InkWell onTap null).
      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      verifyNever(() => repo.verifyPin(any()));
      expect(popResult, isNull);
      expect(popped, isFalse);
    },
  );

  testWidgets(
    'kontrol: TIDAK lockout saat masuk → keypad enabled & countdown tak tampil',
    (tester) async {
      // setUp() sudah menstub getLockedUntilMs()=>0 (tak lockout).
      await pumpAndOpen(tester);

      final countdownPattern = RegExp(
        RegExp.escape(l10n.applockLockedWait(999)).replaceAll('999', r'\d+'),
      );
      expect(find.textContaining(countdownPattern), findsNothing);
      final keypad = tester.widget<PinKeypad>(find.byType(PinKeypad));
      expect(keypad.enabled, isTrue);
    },
  );
}
