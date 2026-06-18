import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TimezoneCity {
  const TimezoneCity({
    required this.city,
    required this.country,
    required this.iana,
    required this.gmt,
  });
  final String city;
  final String country;
  final String iana;
  final String gmt; // "+07:00" / "-08:00"

  /// "+07:00" → "+7", "+05:30" → "+5:30", "+00:00" → "+0".
  String get _gmtShort {
    final sign = gmt[0];
    final parts = gmt.substring(1).split(':');
    final h = int.parse(parts[0]);
    final m = parts.length > 1 ? int.parse(parts[1]) : 0;
    return m == 0 ? '$sign$h' : '$sign$h:${parts[1]}';
  }

  String get label => '$city · GMT$_gmtShort';
}

class TimezoneResolver {
  TimezoneResolver(this._cities);
  final List<TimezoneCity> _cities;

  /// Factory: muat dari aset bundle (dipakai produksi via DI).
  static Future<TimezoneResolver> load() async {
    final raw = await rootBundle.loadString('assets/data/timezone_cities.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final cities = (json['cities'] as List)
        .map((e) => TimezoneCity(
              city: e['city'] as String,
              country: e['country'] as String,
              iana: e['iana'] as String,
              gmt: e['gmt'] as String,
            ))
        .toList();
    return TimezoneResolver(cities);
  }

  List<TimezoneCity> citiesIn(String country) =>
      _cities.where((c) => c.country == country).toList();

  TimezoneCity? cityToTz(String city, String country) => _cities
      .where((c) => c.city == city && c.country == country)
      .cast<TimezoneCity?>()
      .firstWhere((_) => true, orElse: () => null);

  /// Reverse: IANA → label kota (prompt rekonsiliasi launch, §5).
  String? labelForIana(String iana) => _cities
      .where((c) => c.iana == iana)
      .map((c) => c.label)
      .cast<String?>()
      .firstWhere((_) => true, orElse: () => null);

  /// Daftar zona unik (1 entri per IANA) utk fallback "pilih zona waktu langsung"
  /// saat kota user TAK ada di dataset (§5, B-2). Reuse dataset — tanpa data baru.
  List<TimezoneCity> distinctZones() {
    final seen = <String>{};
    return _cities.where((c) => seen.add(c.iana)).toList();
  }
}
