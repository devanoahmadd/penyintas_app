part of 'budget_settings_bloc.dart';

abstract class BudgetSettingsState extends Equatable {
  const BudgetSettingsState();
  @override
  List<Object?> get props => [];
}

class BudgetSettingsInitial extends BudgetSettingsState {
  const BudgetSettingsInitial();
}

class BudgetSettingsLoading extends BudgetSettingsState {
  const BudgetSettingsLoading();
}

class BudgetSettingsLoaded extends BudgetSettingsState {
  const BudgetSettingsLoaded(this.settings);
  final BudgetSettingsEntity settings;
  @override
  List<Object> get props => [settings];
}

class BudgetSettingsSaving extends BudgetSettingsState {
  const BudgetSettingsSaving();
}

class BudgetSettingsSaved extends BudgetSettingsState {
  const BudgetSettingsSaved();
}

class BudgetSettingsError extends BudgetSettingsState {
  const BudgetSettingsError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
