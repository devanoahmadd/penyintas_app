// Test tambahan di luar daftar minimal brief — ChangePinPage merangkai
// verifyPinWithLockout + SetPinPage, dan rangkaian (glue) itu sendiri
// belum tercakup oleh test unit helper maupun test SetPinPage terpisah.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/change_pin_page.dart';

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

  Future<void> tapDigits(WidgetTester tester, List<String> digits) async {
    for (final d in digits) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
  }

  Future<void> pumpAndEnter(WidgetTester tester, List<String> digits) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: [_SyncL10nDelegate(l10n)],
      locale: const Locale('id'),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              popResult = await Navigator.of(ctx).push<bool>(
                MaterialPageRoute(
                    builder: (_) => const ChangePinPage(uid: 'u1')),
              );
              popped = true;
            },
            child: const Text('go'),
          ),
        ),
      ),
    ));
    // Frame kedua wajib — frame pertama baru meng-attach root widget, belum
    // merender tombol "go" (lihat catatan sama di set_pin_page_test.dart).
    await tester.pump();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tapDigits(tester, digits);
  }

  testWidgets('PIN lama benar → dorong SetPinPage untuk PIN baru',
      (tester) async {
    when(() => repo.verifyPin('111111')).thenAnswer((_) async => true);
    await pumpAndEnter(tester, ['1', '1', '1', '1', '1', '1']);
    await tester.pumpAndSettle();
    expect(find.text(l10n.applockSetTitle), findsOneWidget);
  });

  testWidgets(
      'PIN lama benar → PIN baru cocok → setPin dipanggil → pop(true) sampai pemanggil',
      (tester) async {
    when(() => repo.verifyPin('111111')).thenAnswer((_) async => true);
    when(() => repo.setPin(any(), any())).thenAnswer((_) async {});
    await pumpAndEnter(tester, ['1', '1', '1', '1', '1', '1']);
    await tester.pumpAndSettle();
    await tapDigits(tester, ['2', '2', '2', '2', '2', '2']); // set baru
    await tester.pump();
    await tapDigits(tester, ['2', '2', '2', '2', '2', '2']); // confirm
    await tester.pumpAndSettle();
    verify(() => repo.setPin('222222', 'u1')).called(1);
    expect(popped, isTrue);
    expect(popResult, isTrue);
  });

  testWidgets(
      'PIN lama salah tepat blok 5 → recordFailedAttempt + pop(false), tak pernah dorong SetPinPage',
      (tester) async {
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 5);
    await pumpAndEnter(tester, ['0', '0', '0', '0', '0', '0']);
    expect(popResult, isFalse);
    verify(() => repo.recordFailedAttempt()).called(1);
    verifyNever(() => repo.setPin(any(), any()));
    expect(find.text(l10n.applockSetTitle), findsNothing);
  });
}
