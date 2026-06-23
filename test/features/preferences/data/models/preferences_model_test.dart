import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/preferences/data/models/preferences_model.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

void main() {
  group('PreferencesModel', () {
    test('fromFirestore memetakan SEMUA 13 field (CF-2: anti typo-mapping senyap)', () {
      // Tiap nilai input sengaja ≠ fallback: kalau salah satu key di-typo
      // (mis. d['homecity'] alih-alih d['homeCity']), model jatuh ke default/null
      // dan assert ini GAGAL — bukan lolos diam-diam. Batas serialisasi ini
      // diwarisi budget-warning (timezone) & Spec 2 (currency).
      final m = PreferencesModel.fromFirestore({
        'timezone': 'Europe/Moscow', // ≠ Asia/Jakarta
        'baseCurrency': 'USD', // ≠ IDR (3-char lolos clamp)
        'homeCurrency': 'SGD', // ≠ IDR
        'language': 'en', // ≠ id
        'displayName': 'Devano', // fallback null
        'status': 'student', // fallback null (∈ {student,worker})
        'currentCountry': 'RU', // ≠ ID (2-char lolos clamp)
        'currentCity': 'Moscow', // fallback null
        'homeCountry': 'SG', // ≠ ID
        'homeCity': 'Surabaya', // fallback null
        'isPerantau': true, // ≠ false
        'profileCompleted': true, // ≠ false
        'schemaVersion': 2, // ≠ fallback 1
        'updatedAt': Timestamp.now(),
      });
      expect(m.timezone, 'Europe/Moscow');
      expect(m.baseCurrency, 'USD');
      expect(m.homeCurrency, 'SGD');
      expect(m.language, 'en');
      expect(m.displayName, 'Devano');
      expect(m.status, 'student');
      expect(m.currentCountry, 'RU');
      expect(m.currentCity, 'Moscow');
      expect(m.homeCountry, 'SG');
      expect(m.homeCity, 'Surabaya');
      expect(m.isPerantau, true);
      expect(m.profileCompleted, true);
      expect(m.schemaVersion, 2);
    });

    test('fromFirestore: field hilang → default aman (tak crash)', () {
      final m = PreferencesModel.fromFirestore({'language': 'id'});
      expect(m.timezone, 'Asia/Jakarta');
      expect(m.baseCurrency, 'IDR');
      expect(m.currentCountry, 'ID');
      expect(m.isPerantau, false);
      expect(m.profileCompleted, false);
    });

    test('fromFirestore: nilai liar di-CLAMP (M1 trust-boundary)', () {
      final m = PreferencesModel.fromFirestore({
        'language': 'fr', // tak dikenal → id
        'status': 'ceo', // tak dikenal → null
        'currentCountry': 'RUS', // bukan alpha-2 → ID
        'baseCurrency': 'RUBLE', // bukan 3-char → IDR
        'timezone': '', // kosong → default
      });
      expect(m.language, 'id');
      expect(m.status, isNull);
      expect(m.currentCountry, 'ID');
      expect(m.baseCurrency, 'IDR');
      expect(m.timezone, 'Asia/Jakarta');
    });

    test('fromFirestore: tipe SALAH (bukan string/bool/num) → fallback aman, tak crash (T-2)', () {
      // Trust-boundary: dokumen lama/ter-tamper bisa simpan tipe salah. `as` mentah
      // akan MELEMPAR → satu field rusak menggugurkan fetch. Harus di-fallback, bukan crash.
      final m = PreferencesModel.fromFirestore(const {
        'timezone': 123, // bukan String → default
        'isPerantau': 'true', // String, bukan bool → false
        'profileCompleted': 1, // int, bukan bool → false
        'schemaVersion': '1', // String, bukan num → 1
        'language': 99, // bukan String → id
        'currentCountry': 7, // bukan String → ID
      });
      expect(m.timezone, 'Asia/Jakarta');
      expect(m.isPerantau, false);
      expect(m.profileCompleted, false);
      expect(m.schemaVersion, 1);
      expect(m.language, 'id');
      expect(m.currentCountry, 'ID');
    });

    test('toFirestore menulis field wajib + updatedAt serverTimestamp', () {
      final map = PreferencesModel.fromEntity(PreferencesEntity.defaults.copyWith(
        timezone: 'Europe/Moscow',
        profileCompleted: true,
      )).toFirestore();
      // hasAll (rules) — field wajib hadir
      for (final k in [
        'timezone', 'baseCurrency', 'homeCurrency', 'language',
        'currentCountry', 'homeCountry', 'isPerantau', 'profileCompleted',
        'schemaVersion', 'updatedAt',
      ]) {
        expect(map.containsKey(k), true, reason: 'wajib: $k');
      }
      expect(map['updatedAt'], isA<FieldValue>()); // serverTimestamp
    });

    test('toFirestore: field opsional null tidak ditulis (hasOnly bersih)', () {
      final map = PreferencesModel.fromEntity(PreferencesEntity.defaults).toFirestore();
      expect(map.containsKey('displayName'), false);
      expect(map.containsKey('currentCity'), false);
      expect(map.containsKey('homeCity'), false);
      expect(map.containsKey('status'), false);
    });

    test('toFirestore key-set == kontrak bersama (C1: anti-drift Dart↔rules)', () {
      // Satu sumber kebenaran field: firestore-tests/preferences_contract.json
      // dipakai SISI Dart (sini) DAN sisi rules-test JS (A8). Kalau model & rules
      // berdrift, salah satu test ini GAGAL — bukan diam-diam gagal di produksi.
      final contract = jsonDecode(
        File('firestore-tests/preferences_contract.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final required = (contract['required'] as List).cast<String>().toSet();
      // defaults = tanpa field opsional → key-set HARUS sama persis dgn `required`.
      final keys = PreferencesModel.fromEntity(PreferencesEntity.defaults)
          .toFirestore()
          .keys
          .toSet();
      expect(keys, required,
          reason: 'toFirestore() drift dari preferences_contract.json (sinkronkan model/rules/kontrak)');
    });

    test('updatedAt (server) TIDAK ikut fromFirestore', () {
      final m = PreferencesModel.fromFirestore({
        'language': 'id', 'updatedAt': Timestamp.now(),
      });
      // model tak menyimpan updatedAt sebagai field; round-trip toFirestore baru men-set server time
      final back = m.toFirestore();
      expect(back['updatedAt'], isA<FieldValue>());
    });
  });
}
