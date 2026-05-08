import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/settings/domain/entities/app_settings_entity.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._db) : super(const SettingsState.initial()) {
    on<SettingsLoaded>(_onLoaded);
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  final AppDatabase _db;

  Future<void> _onLoaded(
    SettingsLoaded event,
    Emitter<SettingsState> emit,
  ) async {
    final saved = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (saved == null) {
      await _persist(state);
      return;
    }
    emit(state.copyWith(
      themeMode: AppSettingsEntity.themeModeFromString(saved.themeMode),
      locale: saved.locale,
    ));
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(themeMode: event.themeMode));
    await _persist(state);
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(locale: event.locale));
    await _persist(state);
  }

  Future<void> _persist(SettingsState s) async {
    try {
      final existing = await (_db.select(_db.appSettings)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      await _db.into(_db.appSettings).insertOnConflictUpdate(AppSettingsCompanion(
            id: const Value(1),
            themeMode: Value(AppSettingsEntity.themeModeToString(s.themeMode)),
            locale: Value(s.locale),
            onboardingCompleted: Value(existing?.onboardingCompleted ?? false),
            monthlyIncome: Value(existing?.monthlyIncome ?? 0),
            paymentDate: Value(existing?.paymentDate ?? 1),
            fixedExpenses: Value(existing?.fixedExpenses ?? 0),
            emergencyFundPct: Value(existing?.emergencyFundPct ?? 0.10),
            onboardingCreatedAt: Value(existing?.onboardingCreatedAt),
          ));
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }
}
