import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

part 'profile_setup_state.dart';

/// Draft profil in-memory (bukan tabel Drift, §4.2 YAGNI). save() → repo.
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit({
    required PreferencesRepository repo,
    required TimezoneResolver tz,
    String? initialName,
    bool autoPrefill =
        true, // Temuan 5: seam determinisme test (produksi = true)
  }) : _repo = repo,
       _tz = tz,
       super(ProfileSetupState(displayName: initialName)) {
    if (autoPrefill) prefill();
  }

  final PreferencesRepository _repo;
  final TimezoneResolver _tz;

  // B-5: prefill bahasa dari preferences yang sudah di-seed Phase A
  // (app_settings.locale → preferences.language). User EN tak lagi melihat toggle
  // default 'id'. Ada 1-frame flash ('id' → nilai tersimpan) — wajar untuk layar
  // onboarding. Dibungkus try/catch: read gagal → tetap default 'id'.
  //
  // Temuan 5: dijadikan PUBLIC + di-gate `autoPrefill` agar blocTest yang meng-assert
  // daftar emisi eksak TAK bergantung pada "kebetulan dedup" (emit language=='id' ==
  // state default → no-op). Unit test sensitif pakai `autoPrefill:false`; page/produksi
  // tetap auto. Bila perlu, test bisa `await c.prefill()` eksplisit.
  Future<void> prefill() async {
    try {
      final p = await _repo.read();
      if (!isClosed) emit(state.copyWith(language: p.language));
    } catch (_) {
      /* biarkan default 'id' */
    }
  }

  void setLanguage(String v) => emit(state.copyWith(language: v));
  // B-4 trust-boundary: clamp ≤80 menyamai rules (A7 M2). Tanpa ini, nama overlong
  // lolos ke local (user lihat "berhasil") tapi mirror DITOLAK permission-denied
  // SELAMANYA (+ memicu assert di remote-ds saat debug). Samakan batas di sumbernya.
  void setName(String v) =>
      emit(state.copyWith(displayName: v.length > 80 ? v.substring(0, 80) : v));
  void setStatus(String v) => emit(state.copyWith(status: v));
  void goToLocation() => emit(state.copyWith(subStep: 1));
  void backToIdentity() => emit(state.copyWith(subStep: 0));

  void setCurrentCountry(String c) =>
      emit(state.copyWith(currentCountry: c, clearCurrentCity: true));

  void setCurrentCity(String city) {
    final iana =
        _tz.cityToTz(city, state.currentCountry)?.iana ?? state.timezone;
    emit(state.copyWith(currentCity: city, timezone: iana));
  }

  void setTimezone(String iana) => emit(state.copyWith(timezone: iana));

  void togglePerantau(bool v) {
    if (v) {
      emit(state.copyWith(isPerantau: true));
    } else {
      // OFF → home = current (invariant A10)
      emit(
        state.copyWith(
          isPerantau: false,
          homeCountry: state.currentCountry,
          clearHomeCity: true,
        ),
      );
    }
  }

  void setHomeCountry(String c) => emit(state.copyWith(homeCountry: c));
  void setHomeCity(String city) => emit(state.copyWith(homeCity: city));

  Future<void> save() async {
    if (state.saving) return; // B-8: cegah double-tap "Selesai" → dua mirror
    emit(state.copyWith(saving: true, error: null));
    final entity = PreferencesEntity(
      timezone: state.timezone,
      baseCurrency: 'IDR', // Spec 1 IDR-seragam (D4)
      homeCurrency: 'IDR',
      language: state.language,
      displayName: state.displayName,
      status: state.status,
      currentCountry: state.currentCountry,
      currentCity: state.currentCity,
      homeCountry: state.isPerantau ? state.homeCountry : state.currentCountry,
      homeCity: state.isPerantau ? state.homeCity : null,
      isPerantau: state.isPerantau,
      profileCompleted: true,
    );
    final res = await _repo.save(entity);
    res.fold(
      (f) => emit(state.copyWith(saving: false, error: f.message)),
      (_) => emit(state.copyWith(saving: false, saved: true)),
    );
  }
}
