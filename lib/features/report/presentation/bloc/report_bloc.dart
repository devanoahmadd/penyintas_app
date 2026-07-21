import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/report/domain/usecases/get_ai_insight_usecase.dart';
import 'package:penyintas_app/features/report/domain/usecases/get_monthly_report_usecase.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_event.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc({
    required GetMonthlyReportUseCase getMonthlyReport,
    required GetAiInsightUseCase getAiInsight,
  }) : _getMonthlyReport = getMonthlyReport,
       _getAiInsight = getAiInsight,
       super(const ReportInitial()) {
    on<LoadReport>(_onLoad, transformer: droppable());
    on<LoadAiInsight>(_onLoadInsight, transformer: droppable());
    on<PreviousMonth>(_onPrevious);
    on<NextMonth>(_onNext);
  }

  final GetMonthlyReportUseCase _getMonthlyReport;
  final GetAiInsightUseCase _getAiInsight;

  Future<void> _onLoad(LoadReport event, Emitter<ReportState> emit) async {
    emit(const ReportLoading());
    final result = await _getMonthlyReport(event.month);
    result.fold((failure) => emit(ReportError(failure.message)), (report) {
      emit(ReportLoaded(report: report, selectedMonth: event.month));
      add(const LoadAiInsight());
    });
  }

  Future<void> _onLoadInsight(
    LoadAiInsight event,
    Emitter<ReportState> emit,
  ) async {
    final current = state;
    if (current is! ReportLoaded) return;
    emit(current.copyWith(isLoadingInsight: true));
    final result = await _getAiInsight(current.report);
    result.fold(
      (_) => emit(current.copyWith(isLoadingInsight: false)),
      (tuple) => emit(
        current.copyWith(
          report: current.report.copyWith(
            aiInsights: tuple.$1,
            savingTip: tuple.$2,
          ),
          isLoadingInsight: false,
        ),
      ),
    );
  }

  void _onPrevious(PreviousMonth event, Emitter<ReportState> emit) {
    final month = _selectedMonth;
    add(LoadReport(DateTime(month.year, month.month - 1)));
  }

  void _onNext(NextMonth event, Emitter<ReportState> emit) {
    final month = _selectedMonth;
    final next = DateTime(month.year, month.month + 1);
    if (next.isAfter(DateTime.now())) return;
    add(LoadReport(next));
  }

  DateTime get _selectedMonth => state is ReportLoaded
      ? (state as ReportLoaded).selectedMonth
      : DateTime.now();
}
