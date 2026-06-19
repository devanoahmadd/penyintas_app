import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

part 'timezone_reconciliation_state.dart';

/// Rekonsiliasi zona waktu saat launch (F5). Membandingkan zona device vs
/// tersimpan; bila beda → usulkan geser (non-blocking, tak pernah silent).
/// `getDeviceTimezone` di-inject agar testable (produksi: FlutterTimezone).
class TimezoneReconciliationCubit extends Cubit<TimezoneReconciliationState> {
  TimezoneReconciliationCubit({
    required PreferencesRepository repo,
    required TimezoneResolver tz,
    required Future<String> Function() getDeviceTimezone,
  })  : _repo = repo,
        _tz = tz,
        _getDeviceTz = getDeviceTimezone,
        super(const TimezoneReconciliationState());

  final PreferencesRepository _repo;
  final TimezoneResolver _tz;
  final Future<String> Function() _getDeviceTz;

  // F-D5/F-D6: zona yang user "Nanti"-kan. Selama instance hidup (cubit = lazySingleton,
  // disajikan via BlocProvider.value), zona ini tak ditawarkan lagi → anti-nag saat
  // remount dashboard. Perubahan zona SUNGGUHAN di tengah sesi tetap bisa di-prompt
  // (de-dup per-zona, bukan hard-latch). Cold-restart me-reset (sengaja, lihat plan).
  String? _snoozedTz;

  // Temuan 4: re-entrancy guard. `check()` dipanggil dari `BlocProvider.value(..)..check()`
  // tiap pageBuilder dashboard di-build (NoTransitionPage bisa rebuild) — tanpa guard ini
  // tiap rebuild memicu I/O (device-tz + repo.read) berulang & berpotensi prompt ganda.
  bool _checking = false;

  /// Dipanggil saat dashboard mount. JANGAN pernah throw (launch path).
  Future<void> check() async {
    if (_checking) return; // Temuan 4: cegah check() tumpang-tindih per rebuild
    _checking = true;
    try {
      final device = (await _getDeviceTz()).trim();
      if (device.isEmpty || device == _snoozedTz) return; // F-D5: hormati snooze
      final prefs = await _repo.read();
      if (device == prefs.timezone) return; // selaras → diam
      final deviceLabel = _tz.labelForIana(device) ?? device;
      if (!isClosed) {
        emit(TimezoneReconciliationState(
          prompt: TimezonePrompt(
            deviceTz: device,
            deviceLabel: deviceLabel,
            storedLabel: _storedLabel(prefs),
          ),
        ));
      }
    } catch (e, s) {
      _log(e, s); // never crash launch
    } finally {
      _checking = false; // Temuan 4: WAJIB reset walau ada early-return di atas
    }
  }

  /// F-D5b: label zona tersimpan. Pakai `currentCity` HANYA bila konsisten dgn
  /// `timezone` tersimpan (`cityToTz(city,country).iana == timezone`). Ini
  /// menyembuhkan kasus pasca-`confirm`: `confirm` hanya menggeser `timezone`,
  /// sehingga `currentCity` lama bisa BASI — tanpa cek ini, prompt berikutnya
  /// menampilkan kota yang salah (B-8c). Tanpa butuh `copyWith(currentCity: null)`.
  String _storedLabel(PreferencesEntity p) {
    final city = p.currentCity;
    final country = p.currentCountry;
    if (city != null && city.isNotEmpty && country.isNotEmpty) {
      final m = _tz.cityToTz(city, country);
      if (m != null && m.iana == p.timezone) return city; // kota cocok zona → akurat
    }
    return _tz.labelForIana(p.timezone) ?? p.timezone; // selain itu → label dari zona
  }

  /// User setuju pakai zona device. Update timezone saja (full-doc via repo.save).
  /// `currentCity` dibiarkan — staleness ditangani `_storedLabel` (relokasi penuh =
  /// editor profil).
  Future<void> confirm() async {
    final p = state.prompt;
    if (p == null) return;
    try {
      final prefs = await _repo.read();
      await _repo.save(prefs.copyWith(timezone: p.deviceTz));
    } catch (e, s) {
      _log(e, s);
    }
    // F-D5c: confirm MENGUBAH zona tersimpan → snooze lama (zona lain yg pernah
    // di-"Nanti"-kan sesi ini) kini basi konteksnya. Tanpa reset ini, edge travel
    // X→dismiss → Y→confirm → balik X tak akan di-prompt walau stored sudah ≠ X.
    _snoozedTz = null;
    if (!isClosed) emit(const TimezoneReconciliationState());
  }

  void dismiss() {
    _snoozedTz = state.prompt?.deviceTz; // F-D5: snooze zona ini utk sesi berjalan
    emit(const TimezoneReconciliationState());
  }

  static void _log(Object e, StackTrace s) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s);
    } catch (_) {}
  }
}
