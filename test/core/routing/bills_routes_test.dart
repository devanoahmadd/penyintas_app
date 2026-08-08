import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/routing/app_router.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

/// Rute Tagihan diuji dalam TIGA lapis (lihat tabel di rencana T6).
///
/// Lapis 1 & 2 memanggil `buildBillsRoute()` dan `billEditGuard()` YANG NYATA
/// dari `app_router.dart` — merusak produksi membuatnya merah. Router aplikasi
/// penuh sengaja tidak dipakai: `createAppRouter()` menyentuh
/// `FirebaseAuth.instance` dan seluruh `injection_container`.
///
/// Lapis 3 memakai router mini. Di sana tiruan SAH, karena yang diuji adalah
/// perilaku go_router (redirect mendahului builder), bukan kode kita.
void main() {
  BillEntity buatBill() => BillEntity(
    id: 7,
    name: 'Kos Bu Tini',
    estimatedAmount: 750000,
    category: 'fixed',
    isFixedNeed: true,
    dueDate: DateTime(2026, 8, 10),
    recurrence: Recurrence.monthly,
    installmentsPaid: 0,
    reminderEnabled: true,
    status: BillStatus.active,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  // ══ LAPIS 1 — BENTUK rute NYATA ════════════════════════════════════════
  //
  // Tak ada `pumpWidget` di sini, jadi tak ada builder yang dijalankan dan
  // tak ada GetIt yang perlu disiapkan. Yang diperiksa cuma objeknya.

  group('buildBillsRoute — bentuk', () {
    test('induk /bills punya tepat dua rute anak', () {
      final route = buildBillsRoute();
      expect(route.path, '/bills');
      expect(route.routes, hasLength(2));
    });

    test('anak memakai path RELATIF — tanpa garis miring di depan', () {
      final anak = buildBillsRoute().routes.cast<GoRoute>();
      expect(anak[0].path, 'new');
      expect(anak[1].path, ':id/edit');
      for (final r in anak) {
        expect(
          r.path.startsWith('/'),
          isFalse,
          reason: 'path absolut di rute bersarang membuat /bills/new tak '
              'pernah cocok',
        );
      }
    });

    test('redirect HANYA pada :id/edit, tidak pada new', () {
      final anak = buildBillsRoute().routes.cast<GoRoute>();
      expect(anak[0].redirect, isNull, reason: '/bills/new tak punya extra');
      expect(
        anak[1].redirect,
        isNotNull,
        reason: 'tanpa penjaga, deep-link ke /bills/7/edit = cast exception',
      );
    });
  });

  // ══ LAPIS 2 — PENJAGA nyata ════════════════════════════════════════════

  group('billEditGuard', () {
    test('BillEntity → lanjut', () {
      expect(billEditGuard(buatBill()), isNull);
    });

    test('null → belokkan ke /bills', () {
      expect(billEditGuard(null), '/bills');
    });

    test('tipe salah → belokkan, bukan melempar', () {
      expect(billEditGuard('bukan bill'), '/bills');
      expect(billEditGuard(42), '/bills');
      expect(billEditGuard(<String, Object>{}), '/bills');
    });
  });

  // ══ LAPIS 3 — KONTRAK go_router ════════════════════════════════════════
  //
  // Router mini, dan di sini itu SAH: yang diuji adalah janji pustaka pihak
  // ketiga — `redirect` berjalan sebelum `builder` — bukan kode kita. Kalau
  // go_router suatu saat membalik urutannya, penjaga `extra` kita jadi hiasan
  // dan test inilah yang memberi tahu.

  /// Router mini yang MENIRU bentuk rute nyata. Builder-nya sengaja remeh
  /// supaya tak ada BLoC/GetIt yang perlu hidup.
  GoRouter buatRouter({required void Function(BillEntity?) catatBill}) {
    return GoRouter(
      initialLocation: '/bills',
      routes: [
        GoRoute(
          path: '/bills',
          builder: (_, _) => const Scaffold(body: Text('daftar')),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, _) {
                catatBill(null);
                return const Scaffold(body: Text('form'));
              },
            ),
            GoRoute(
              path: ':id/edit',
              // Memanggil penjaga NYATA, bukan menyalin logikanya.
              redirect: (context, state) => billEditGuard(state.extra),
              builder: (_, state) {
                catatBill(state.extra as BillEntity);
                return const Scaffold(body: Text('form'));
              },
            ),
          ],
        ),
      ],
    );
  }

  testWidgets('/bills/new membangun form dalam mode tambah', (tester) async {
    BillEntity? diterima;
    var terpanggil = false;
    final router = buatRouter(
      catatBill: (b) {
        diterima = b;
        terpanggil = true;
      },
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.push('/bills/new');
    await tester.pumpAndSettle();

    expect(terpanggil, isTrue);
    expect(diterima, isNull);
  });

  testWidgets('/bills/:id/edit meneruskan BillEntity dari extra', (
    tester,
  ) async {
    BillEntity? diterima;
    final router = buatRouter(catatBill: (b) => diterima = b);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final bill = buatBill();
    router.push('/bills/7/edit', extra: bill);
    await tester.pumpAndSettle();

    expect(diterima, same(bill));
  });

  testWidgets('extra null pada /bills/:id/edit dibelokkan ke /bills — '
      'builder TIDAK pernah dijalankan', (tester) async {
    var builderJalan = false;
    final router = buatRouter(catatBill: (_) => builderJalan = true);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.push('/bills/7/edit');
    await tester.pumpAndSettle();

    expect(builderJalan, isFalse, reason: 'redirect harus mendahului builder');
    expect(find.text('daftar'), findsOneWidget);
  });

  testWidgets('extra bertipe salah juga dibelokkan, bukan cast exception', (
    tester,
  ) async {
    var builderJalan = false;
    final router = buatRouter(catatBill: (_) => builderJalan = true);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.push('/bills/7/edit', extra: 'bukan bill');
    await tester.pumpAndSettle();

    expect(builderJalan, isFalse);
    expect(tester.takeException(), isNull);
  });
}
