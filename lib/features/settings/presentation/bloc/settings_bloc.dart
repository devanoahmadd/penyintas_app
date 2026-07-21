import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:penyintas_app/features/settings/domain/entities/app_settings_entity.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._db, this._prefs) : super(const SettingsState.initial()) {
    on<SettingsLoaded>(_onLoaded);
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  final AppDatabase _db;
  final PreferencesRepository _prefs; // C2: language canonical

  // M2 defense-in-depth: `preferences.language` adalah locale-live (app.dart:67
  // `Locale(settings.locale)`). Clamp di boundary baca/tulis agar nilai korup /
  // bootstrap remote→local (Phase D) tak pernah jadi Locale liar.
  static const _supported = {'id', 'en'};
  String _clampLang(String v) => _supported.contains(v) ? v : 'id';

  // Crashlytics best-effort — wrap agar TAK pernah throw (mis. Firebase belum init
  // di unit test, atau plugin gagal). Pola sama dgn `dashboard_bloc.dart:58` &
  // `PreferencesRepositoryImpl._logError`. Tanpa ini, error-path test (M1) crash.
  static void _log(Object e, StackTrace s) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s);
    } catch (_) {}
  }

  Future<void> _onLoaded(
    SettingsLoaded event,
    Emitter<SettingsState> emit,
  ) async {
    // Theme dari app_settings; language dari preferences (canonical pasca-cutover).
    final saved = await (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    PreferencesEntity prefs;
    try {
      prefs = await _prefs.read();
    } catch (e, s) {
      _log(e, s);
      prefs = PreferencesEntity.defaults; // fail-safe: bahasa default
    }
    emit(
      state.copyWith(
        themeMode: saved != null
            ? AppSettingsEntity.themeModeFromString(saved.themeMode)
            : state.themeMode,
        locale: _clampLang(prefs.language), // M2: clamp boundary {id,en}
      ),
    );
    if (saved == null)
      await _persistTheme(state); // seed baris theme bila belum ada
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(themeMode: event.themeMode));
    await _persistTheme(state);
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    final previous = state.locale; // M1: utk revert bila persist gagal
    final next = _clampLang(event.locale); // M2: clamp boundary {id,en}
    emit(
      state.copyWith(locale: next),
    ); // optimistic: locale-live langsung berubah

    PreferencesEntity current;
    try {
      current = await _prefs.read();
    } catch (e, s) {
      _log(e, s);
      emit(
        state.copyWith(locale: previous),
      ); // M1: jujur — UI mundur, bukan phantom-sukses
      return;
    }
    // save() menangkap error lokalnya sendiri → kembalikan Left (TAK throw). Wajib
    // inspeksi Either: kalau cuma try/catch, Left lolos & UI klaim sukses palsu →
    // bahasa balik saat restart (silent revert). M1.
    final res = await _prefs.save(current.copyWith(language: next));
    res.fold((f) {
      _log(f, StackTrace.current);
      emit(state.copyWith(locale: previous)); // M1: revert
    }, (_) {});
  }

  /// Hanya theme yg canonical di app_settings. `locale` dipertahankan (vestigial,
  /// kolom NOT NULL) agar tak meng-clobber; tak ada yg membacanya pasca-cutover.
  Future<void> _persistTheme(SettingsState s) async {
    try {
      final existing = await (_db.select(
        _db.appSettings,
      )..where((t) => t.id.equals(1))).getSingleOrNull();
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion(
              id: const Value(1),
              themeMode: Value(
                AppSettingsEntity.themeModeToString(s.themeMode),
              ),
              locale: Value(existing?.locale ?? 'id'),
              onboardingCompleted: Value(
                existing?.onboardingCompleted ?? false,
              ),
              monthlyIncome: Value(existing?.monthlyIncome ?? 0),
              paymentDate: Value(existing?.paymentDate ?? 1),
              fixedExpenses: Value(existing?.fixedExpenses ?? 0),
              emergencyFundPct: Value(existing?.emergencyFundPct ?? 0.10),
              onboardingCreatedAt: Value(existing?.onboardingCreatedAt),
            ),
          );
    } catch (e, stack) {
      _log(e, stack);
    }
  }
}
