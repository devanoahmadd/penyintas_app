// test/features/profile/presentation/widgets/city_picker_test.dart
//
// Widget test untuk CityPicker — TDD Step 1 (RED).
// Kontrak keys: city_search, city_pick_tz_direct, tz_direct_search.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';
import 'package:penyintas_app/features/profile/presentation/widgets/city_picker.dart';

void main() {
  final tz = TimezoneResolver(const [
    TimezoneCity(
      city: 'Jakarta',
      country: 'ID',
      iana: 'Asia/Jakarta',
      gmt: '+07:00',
    ),
    TimezoneCity(
      city: 'Makassar',
      country: 'ID',
      iana: 'Asia/Makassar',
      gmt: '+08:00',
    ),
    TimezoneCity(
      city: 'Moscow',
      country: 'RU',
      iana: 'Europe/Moscow',
      gmt: '+03:00',
    ),
  ]);

  group('CityPicker — discope', () {
    testWidgets('hanya menampilkan kota negara terpilih', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CityPicker(country: 'ID', resolver: tz),
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Jakarta · GMT+7'), findsOneWidget);
      expect(find.text('Makassar · GMT+8'), findsOneWidget);
      // Moscow milik RU — tidak boleh muncul
      expect(find.textContaining('Moscow'), findsNothing);
    });
  });

  group('CityPicker — search filter', () {
    testWidgets('search memfilter daftar kota', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CityPicker(country: 'ID', resolver: tz),
          ),
        ),
      );
      await t.pumpAndSettle();

      await t.enterText(find.byKey(const Key('city_search')), 'Maka');
      await t.pumpAndSettle();

      expect(find.text('Makassar · GMT+8'), findsOneWidget);
      expect(find.text('Jakarta · GMT+7'), findsNothing);
    });
  });

  group('CityPicker — escape hatch (B-2)', () {
    testWidgets(
      'negara tanpa kota di dataset → escape hatch city_pick_tz_direct selalu tampil',
      (t) async {
        // 'QA' tidak ada di dataset test → citiesIn kosong
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CityPicker(country: 'QA', resolver: tz),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.byKey(const Key('city_pick_tz_direct')), findsOneWidget);
      },
    );

    testWidgets(
      'negara dengan kota → escape hatch city_pick_tz_direct TETAP tampil',
      (t) async {
        // Escape hatch harus SELALU ada (di paling bawah daftar)
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CityPicker(country: 'ID', resolver: tz),
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.byKey(const Key('city_pick_tz_direct')), findsOneWidget);
      },
    );

    testWidgets(
      'negara tanpa kota → escape hatch menjadi SATU-SATUNYA konten kota',
      (t) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CityPicker(country: 'QA', resolver: tz),
            ),
          ),
        );
        await t.pumpAndSettle();

        // Tidak ada item kota lain selain escape hatch
        expect(find.byType(ListTile), findsOneWidget);
      },
    );

    testWidgets(
      'tap escape hatch membuka sheet zona langsung dengan key tz_direct_search',
      (t) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CityPicker(country: 'QA', resolver: tz),
            ),
          ),
        );
        await t.pumpAndSettle();

        await t.tap(find.byKey(const Key('city_pick_tz_direct')));
        await t.pumpAndSettle();

        // Sheet zona langsung harus terbuka dengan search field
        expect(find.byKey(const Key('tz_direct_search')), findsOneWidget);
      },
    );
  });

  group('CityPicker — hasil pop', () {
    testWidgets('tap kota → Navigator.pop dengan String nama kota', (t) async {
      dynamic popResult;

      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                popResult = await Navigator.of(ctx).push<dynamic>(
                  MaterialPageRoute(
                    builder: (_) => CityPicker(country: 'ID', resolver: tz),
                  ),
                );
              },
              child: const Text('Buka'),
            ),
          ),
        ),
      );

      await t.tap(find.text('Buka'));
      await t.pumpAndSettle();

      await t.tap(find.text('Jakarta · GMT+7'));
      await t.pumpAndSettle();

      expect(popResult, equals('Jakarta'));
    });
  });

  group('CityPicker — TimezonePick type', () {
    testWidgets('TimezonePick memiliki field iana', (t) async {
      // Pastikan tipe terdefinisi dan bisa dibuat
      const pick = TimezonePick('Asia/Jakarta');
      expect(pick.iana, equals('Asia/Jakarta'));
      await t.pumpWidget(const MaterialApp(home: SizedBox()));
    });
  });
}
