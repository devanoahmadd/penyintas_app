// lib/features/profile/presentation/cubit/profile_edit_cubit.dart
//
// ProfileEditCubit — editor profil (C3).
// Muat PreferencesEntity yang ada → sunting → save().
// TIDAK menyunting bahasa (C-α) — `language` draft dipertahankan apa adanya.
//
// Invarian utama:
//   H1: load gagal → draft null + error; save() no-op (tak menimpa profil asli)
//   H2: ganti negara → currentLocationResolved=false; save() diblok s/d kota/tz dipilih
//   M3: isDirty = draft != loaded (Equatable); re-baseline pasca-simpan → isDirty=false
//   B-8: re-entran guard di save() (saving flag)

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

part 'profile_edit_state.dart';

class ProfileEditCubit extends Cubit<ProfileEditState> {
  ProfileEditCubit({
    required PreferencesRepository repo,
    required TimezoneResolver tz,
  }) : _repo = repo,
       _tz = tz,
       super(const ProfileEditState()) {
    _load();
  }

  final PreferencesRepository _repo;
  final TimezoneResolver _tz;

  Future<void> _load() async {
    try {
      final p = await _repo.read();
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: false,
            draft: p,
            loaded: p,
            currentLocationResolved: true,
          ),
        );
      }
    } catch (_) {
      // H1: JANGAN fallback ke defaults. Draft null → halaman tampil error+Retry,
      // tombol Simpan tak ada di state ini → tak bisa menimpa profil asli dgn kosong.
      if (!isClosed) emit(state.copyWith(loading: false, error: 'load_failed'));
    }
  }

  /// H1: tombol "Coba lagi" di error-state. Reset ke loading lalu muat ulang.
  Future<void> reload() async {
    emit(const ProfileEditState());
    await _load();
  }

  void _patch(PreferencesEntity Function(PreferencesEntity) f) {
    final d = state.draft;
    if (d == null) return;
    emit(state.copyWith(draft: f(d)));
  }

  /// Clamp nama ≤80 (A7 M2).
  void setName(String v) => _patch(
    (d) => d.copyWith(displayName: v.length > 80 ? v.substring(0, 80) : v),
  );

  void setStatus(String v) => _patch((d) => d.copyWith(status: v));

  void setCurrentCountry(String c) {
    final d = state.draft;
    if (d == null) return;
    // H2: kota direset → timezone basi s/d kota/tz baru dipilih.
    emit(
      state.copyWith(
        draft: _clearCurrentCity(d, currentCountry: c),
        currentLocationResolved: false,
      ),
    );
  }

  void setCurrentCity(String city) {
    final d = state.draft;
    if (d == null) return;
    final iana = _tz.cityToTz(city, d.currentCountry)?.iana ?? d.timezone;
    emit(
      state.copyWith(
        draft: d.copyWith(currentCity: city, timezone: iana),
        currentLocationResolved: true, // H2: tz kini cocok dgn kota terpilih
      ),
    );
  }

  /// H2: escape-hatch B-2 (negara tanpa kota di dataset) → set tz eksplisit → resolved.
  void setTimezone(String iana) {
    final d = state.draft;
    if (d == null) return;
    emit(
      state.copyWith(
        draft: d.copyWith(timezone: iana),
        currentLocationResolved: true,
      ),
    );
  }

  void togglePerantau(bool v) {
    final d = state.draft;
    if (d == null) return;
    if (v) {
      emit(state.copyWith(draft: d.copyWith(isPerantau: true)));
    } else {
      // OFF → home = current (invariant A10); homeCity = null (reset eksplisit)
      emit(
        state.copyWith(
          draft: _clearHomeCity(
            d,
            isPerantau: false,
            homeCountry: d.currentCountry,
          ),
        ),
      );
    }
  }

  void setHomeCountry(String c) {
    final d = state.draft;
    if (d == null) return;
    emit(state.copyWith(draft: _clearHomeCity(d, homeCountry: c)));
  }

  void setHomeCity(String city) => _patch((d) => d.copyWith(homeCity: city));

  Future<void> save() async {
    final d = state.draft;
    if (d == null || state.saving) return; // H1 no-op + re-entran guard B-8

    // H2: cegah simpan country/city/timezone tidak konsisten.
    if (!state.currentLocationResolved) {
      emit(state.copyWith(error: 'unresolved_location'));
      return;
    }

    emit(state.copyWith(saving: true));

    // profileCompleted tetap true; IDR-seragam; language TIDAK diubah (C-α)
    final persisted = d.copyWith(profileCompleted: true);
    final res = await _repo.save(persisted);
    if (isClosed) return;
    res.fold(
      (f) => emit(state.copyWith(saving: false, error: f.message)),
      // M3: re-baseline draft & loaded → isDirty=false pasca-simpan.
      // Membuat canPop=true → pop sukses tidak deadlock.
      (_) => emit(
        state.copyWith(
          saving: false,
          saved: true,
          draft: persisted,
          loaded: persisted,
        ),
      ),
    );
  }

  // `copyWith` entity tak bisa set null → rebuild eksplisit utk reset kota.
  PreferencesEntity _clearCurrentCity(
    PreferencesEntity d, {
    required String currentCountry,
  }) => PreferencesEntity(
    timezone: d.timezone, // dipertahankan s/d kota baru dipilih
    baseCurrency: d.baseCurrency,
    homeCurrency: d.homeCurrency,
    language: d.language,
    displayName: d.displayName,
    status: d.status,
    currentCountry: currentCountry,
    currentCity: null, // reset eksplisit
    homeCountry: d.homeCountry,
    homeCity: d.homeCity,
    isPerantau: d.isPerantau,
    profileCompleted: d.profileCompleted,
    schemaVersion: d.schemaVersion,
  );

  PreferencesEntity _clearHomeCity(
    PreferencesEntity d, {
    bool? isPerantau,
    String? homeCountry,
  }) => PreferencesEntity(
    timezone: d.timezone,
    baseCurrency: d.baseCurrency,
    homeCurrency: d.homeCurrency,
    language: d.language,
    displayName: d.displayName,
    status: d.status,
    currentCountry: d.currentCountry,
    currentCity: d.currentCity,
    homeCountry: homeCountry ?? d.homeCountry,
    homeCity: null, // reset eksplisit
    isPerantau: isPerantau ?? d.isPerantau,
    profileCompleted: d.profileCompleted,
    schemaVersion: d.schemaVersion,
  );
}
