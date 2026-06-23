part of 'timezone_reconciliation_cubit.dart';

class TimezonePrompt extends Equatable {
  const TimezonePrompt({
    required this.deviceTz,
    required this.deviceLabel,
    required this.storedLabel,
  });
  final String deviceTz;     // IANA device
  final String deviceLabel;  // ramah, mis. "Moscow · GMT+3"
  final String storedLabel;  // ramah, mis. "Jakarta"

  @override
  List<Object?> get props => [deviceTz, deviceLabel, storedLabel];
}

class TimezoneReconciliationState extends Equatable {
  const TimezoneReconciliationState({this.prompt});
  final TimezonePrompt? prompt; // null = tak ada usulan geser zona

  @override
  List<Object?> get props => [prompt];
}
