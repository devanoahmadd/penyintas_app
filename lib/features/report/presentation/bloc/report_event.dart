import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadReport extends ReportEvent {
  const LoadReport(this.month);
  final DateTime month;

  @override
  List<Object> get props => [month];
}

class LoadAiInsight extends ReportEvent {
  const LoadAiInsight();
}

class PreviousMonth extends ReportEvent {
  const PreviousMonth();
}

class NextMonth extends ReportEvent {
  const NextMonth();
}
