import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/set_pin_page.dart';

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

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  setUp(() {
    repo = _MockRepo();
    if (sl.isRegistered<AppLockRepository>()) {
      sl.unregister<AppLockRepository>();
    }
    sl.registerFactory<AppLockRepository>(() => repo);
    when(() => repo.setPin(any(), any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [_SyncL10nDelegate(l10n)],
        locale: const Locale('id'),
        home: const SetPinPage(uid: 'u1'),
      ),
    );
    // Frame kedua wajib — frame pertama baru meng-attach root widget
    // (lihat View/RawView di widget tree), belum benar-benar merender isi
    // SetPinPage. Tanpa ini, find.text/find.text(digit) tak menemukan apa pun.
    await tester.pump();
  }

  Future<void> enter(WidgetTester tester, List<String> digits) async {
    for (final d in digits) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
  }

  testWidgets('menampilkan judul set PIN di awal', (tester) async {
    await pump(tester);
    expect(find.text(l10n.applockSetTitle), findsOneWidget);
  });

  testWidgets('PIN + konfirmasi cocok → setPin dipanggil', (tester) async {
    await pump(tester);
    await enter(tester, ['1', '2', '3', '4', '5', '6']); // set
    await tester.pump();
    expect(find.text(l10n.applockConfirmTitle), findsOneWidget);
    await enter(tester, ['1', '2', '3', '4', '5', '6']); // confirm
    await tester.pumpAndSettle();
    verify(() => repo.setPin('123456', 'u1')).called(1);
  });

  testWidgets('konfirmasi tak cocok → pesan mismatch, setPin tak dipanggil', (
    tester,
  ) async {
    await pump(tester);
    await enter(tester, ['1', '2', '3', '4', '5', '6']);
    await tester.pump();
    await enter(tester, ['0', '0', '0', '0', '0', '0']);
    await tester.pump();
    expect(find.text(l10n.applockMismatch), findsOneWidget);
    verifyNever(() => repo.setPin(any(), any()));
  });

  testWidgets('setelah mismatch, kembali ke judul set PIN (bukan konfirmasi)', (
    tester,
  ) async {
    await pump(tester);
    await enter(tester, ['1', '2', '3', '4', '5', '6']);
    await tester.pump();
    await enter(tester, ['0', '0', '0', '0', '0', '0']);
    await tester.pump();
    expect(find.text(l10n.applockSetTitle), findsOneWidget);
    expect(find.text(l10n.applockConfirmTitle), findsNothing);
  });
}
