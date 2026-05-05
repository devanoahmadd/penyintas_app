import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:penyintas_app/core/local/app_settings_isar_model.dart';
import 'package:penyintas_app/features/settings/domain/entities/app_settings_entity.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._isar) : super(const SettingsState.initial()) {
    on<SettingsLoaded>(_onLoaded);
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  final Isar _isar;

  Future<void> _onLoaded(
    SettingsLoaded event,
    Emitter<SettingsState> emit,
  ) async {
    final saved = await _isar.appSettingsIsarModels.get(1);
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
    final existing = await _isar.appSettingsIsarModels.get(1);
    final model = AppSettingsIsarModel()
      ..id = 1
      ..themeMode = AppSettingsEntity.themeModeToString(s.themeMode)
      ..locale = s.locale
      ..onboardingCompleted = existing?.onboardingCompleted ?? false
      ..monthlyIncome = existing?.monthlyIncome ?? 0
      ..paymentDate = existing?.paymentDate ?? 1
      ..fixedExpenses = existing?.fixedExpenses ?? 0
      ..emergencyFundPct = existing?.emergencyFundPct ?? 0.10;
    await _isar.writeTxn(() => _isar.appSettingsIsarModels.put(model));
  }
}
