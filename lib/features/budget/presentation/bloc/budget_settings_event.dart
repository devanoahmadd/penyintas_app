part of 'budget_settings_bloc.dart';

abstract class BudgetSettingsEvent extends Equatable {
  const BudgetSettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadBudgetSettings extends BudgetSettingsEvent {
  const LoadBudgetSettings();
}

class SaveBudgetSettings extends BudgetSettingsEvent {
  const SaveBudgetSettings(this.settings);
  final BudgetSettingsEntity settings;
  @override
  List<Object> get props => [settings];
}
