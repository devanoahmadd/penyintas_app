import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';

void main() {
  final cities = const [
    TimezoneCity(city: 'Jakarta', country: 'ID', iana: 'Asia/Jakarta', gmt: '+07:00'),
    TimezoneCity(city: 'Makassar', country: 'ID', iana: 'Asia/Makassar', gmt: '+08:00'),
    TimezoneCity(city: 'Moscow', country: 'RU', iana: 'Europe/Moscow', gmt: '+03:00'),
  ];
  final r = TimezoneResolver(cities);

  test('cityToTz: kota → IANA benar', () {
    expect(r.cityToTz('Moscow', 'RU')!.iana, 'Europe/Moscow');
  });

  test('cityToTz: multi-zona dlm satu negara (Makassar → WITA)', () {
    expect(r.cityToTz('Makassar', 'ID')!.iana, 'Asia/Makassar');
  });

  test('citiesIn: discope ke negara', () {
    expect(r.citiesIn('ID').map((c) => c.city), containsAll(['Jakarta', 'Makassar']));
    expect(r.citiesIn('ID').any((c) => c.country == 'RU'), false);
  });

  test('cityToTz: kota tak ada → null (fallback ditangani caller)', () {
    expect(r.cityToTz('Bandung', 'ID'), isNull);
  });

  test('labelForIana: reverse IANA → label kota (prompt rekonsiliasi §5)', () {
    expect(r.labelForIana('Europe/Moscow'), 'Moscow · GMT+3');
  });

  test('label: format GMT pendek', () {
    expect(cities[0].label, 'Jakarta · GMT+7');
  });

  test('distinctZones: 1 entri per IANA unik (fallback "pilih zona langsung", B-2)', () {
    final zones = r.distinctZones();
    expect(zones.map((z) => z.iana).toSet().length, zones.length);
    expect(zones.any((z) => z.iana == 'Europe/Moscow'), true);
  });
}
