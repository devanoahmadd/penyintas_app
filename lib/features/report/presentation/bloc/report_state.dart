import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/report/domain/entities/report_entity.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportLoaded extends ReportState {
  const ReportLoaded({
    required this.report,
    required this.selectedMonth,
    this.isLoadingInsight = false,
  });

  final ReportEntity report;
  final DateTime selectedMonth;
  final bool isLoadingInsight;

  @override
  List<Object?> get props => [report, selectedMonth, isLoadingInsight];

  ReportLoaded copyWith({
    ReportEntity? report,
    bool? isLoadingInsight,
  }) =>
      ReportLoaded(
        report: report ?? this.report,
        selectedMonth: selectedMonth,
        isLoadingInsight: isLoadingInsight ?? this.isLoadingInsight,
      );
}

class ReportError extends ReportState {
  const ReportError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
