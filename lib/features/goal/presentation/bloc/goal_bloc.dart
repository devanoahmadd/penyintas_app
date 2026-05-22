import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/usecases/complete_goal_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/create_goal_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/delete_goal_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/link_transaction_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/load_goals_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/unlink_transaction_usecase.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';

part 'goal_event.dart';
part 'goal_state.dart';

/// Threshold yang ditandai sebagai milestone: 25%, 50%, 75%, 100%.
const _milestoneThresholds = [0.25, 0.50, 0.75, 1.00];

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  GoalBloc({
    required LoadGoalsUseCase loadGoals,
    required CreateGoalUseCase createGoal,
    required LinkTransactionUseCase linkTransaction,
    required UnlinkTransactionUseCase unlinkTransaction,
    required CompleteGoalUseCase completeGoal,
    required DeleteGoalUseCase deleteGoal,
  })  : _loadGoals = loadGoals,
        _createGoal = createGoal,
        _linkTransaction = linkTransaction,
        _unlinkTransaction = unlinkTransaction,
        _completeGoal = completeGoal,
        _deleteGoal = deleteGoal,
        super(const GoalInitial()) {
    on<LoadGoals>(_onLoad, transformer: droppable());
    on<CreateGoal>(_onCreate, transformer: sequential());
    on<LinkTransaction>(_onLink, transformer: sequential());
    on<UnlinkTransaction>(_onUnlink, transformer: sequential());
    on<CompleteGoal>(_onComplete, transformer: sequential());
    on<DeleteGoal>(_onDelete, transformer: sequential());
    on<MilestoneAcknowledged>(_onMilestoneAcknowledged);
  }

  final LoadGoalsUseCase _loadGoals;
  final CreateGoalUseCase _createGoal;
  final LinkTransactionUseCase _linkTransaction;
  final UnlinkTransactionUseCase _unlinkTransaction;
  final CompleteGoalUseCase _completeGoal;
  final DeleteGoalUseCase _deleteGoal;

  List<GoalEntity> get _currentGoals {
    if (state is GoalLoaded) return (state as GoalLoaded).goals;
    if (state is GoalActionLoading) return (state as GoalActionLoading).goals;
    return const [];
  }

  Future<void> _onLoad(LoadGoals event, Emitter<GoalState> emit) async {
    // Capture previous progress BEFORE clearing state — enables milestone detection
    // when transactions are saved from outside the Goals screen (Dashboard, etc.)
    final prevGoals = _currentGoals;
    final prevProgress = {for (final g in prevGoals) g.id: g.progressPercent};

    emit(const GoalLoading());
    final result = await _loadGoals(const NoParams());
    result.fold(
      (f) => emit(GoalError(f.message)),
      (goals) {
        if (prevGoals.isEmpty) {
          emit(GoalLoaded(goals: goals));
          return;
        }
        int? milestoneGoalId;
        double? milestoneThreshold;
        for (final goal in goals) {
          final prev = prevProgress[goal.id] ?? 0.0;
          final next = goal.progressPercent;
          for (final t in _milestoneThresholds) {
            if (prev < t && next >= t) {
              milestoneGoalId = goal.id;
              milestoneThreshold = t;
              break;
            }
          }
          if (milestoneGoalId != null) break;
        }
        emit(GoalLoaded(
          goals: goals,
          milestoneGoalId: milestoneGoalId,
          milestoneThreshold: milestoneThreshold,
        ));
      },
    );
  }

  Future<void> _onCreate(CreateGoal event, Emitter<GoalState> emit) async {
    final current = _currentGoals;
    emit(GoalActionLoading(current));
    final result = await _createGoal(CreateGoalParams(
      title: event.title,
      targetAmount: event.targetAmount,
      targetDate: event.targetDate,
    ));
    if (result.isLeft()) {
      result.fold((f) => emit(GoalError(f.message)), (_) {});
      return;
    }
    final reload = await _loadGoals(const NoParams());
    reload.fold(
      (f) => emit(GoalError(f.message)),
      (goals) => emit(GoalLoaded(goals: goals)),
    );
  }

  Future<void> _onLink(LinkTransaction event, Emitter<GoalState> emit) async {
    final current = _currentGoals;
    // Catat progress sebelum link untuk deteksi milestone
    final prevProgress = {
      for (final g in current) g.id: g.progressPercent,
    };

    emit(GoalActionLoading(current));
    final result = await _linkTransaction(
        LinkTransactionParams(txId: event.txId, goalId: event.goalId));
    if (result.isLeft()) {
      result.fold((f) => emit(GoalError(f.message)), (_) {});
      return;
    }

    final reload = await _loadGoals(const NoParams());
    reload.fold(
      (f) => emit(GoalError(f.message)),
      (goals) {
        // Cek apakah ada goal yang crossing milestone threshold
        int? milestoneGoalId;
        double? milestoneThreshold;
        for (final goal in goals) {
          if (goal.id != event.goalId) continue;
          final prev = prevProgress[goal.id] ?? 0.0;
          final next = goal.progressPercent;
          for (final t in _milestoneThresholds) {
            if (prev < t && next >= t) {
              milestoneGoalId = goal.id;
              milestoneThreshold = t;
              break;
            }
          }
        }
        emit(GoalLoaded(
          goals: goals,
          milestoneGoalId: milestoneGoalId,
          milestoneThreshold: milestoneThreshold,
        ));
      },
    );
  }

  Future<void> _onUnlink(
      UnlinkTransaction event, Emitter<GoalState> emit) async {
    final current = _currentGoals;
    emit(GoalActionLoading(current));
    final result = await _unlinkTransaction(event.txId);
    if (result.isLeft()) {
      result.fold((f) => emit(GoalError(f.message)), (_) {});
      return;
    }
    final reload = await _loadGoals(const NoParams());
    reload.fold(
      (f) => emit(GoalError(f.message)),
      (goals) => emit(GoalLoaded(goals: goals)),
    );
  }

  Future<void> _onComplete(CompleteGoal event, Emitter<GoalState> emit) async {
    final current = _currentGoals;
    emit(GoalActionLoading(current));
    final result = await _completeGoal(event.goalId);
    if (result.isLeft()) {
      result.fold((f) => emit(GoalError(f.message)), (_) {});
      return;
    }
    final reload = await _loadGoals(const NoParams());
    reload.fold(
      (f) => emit(GoalError(f.message)),
      (goals) => emit(GoalLoaded(goals: goals)),
    );
  }

  Future<void> _onDelete(DeleteGoal event, Emitter<GoalState> emit) async {
    final current = _currentGoals;
    emit(GoalActionLoading(current));
    final result = await _deleteGoal(event.goalId);
    if (result.isLeft()) {
      result.fold((f) => emit(GoalError(f.message)), (_) {});
      return;
    }
    final reload = await _loadGoals(const NoParams());
    reload.fold(
      (f) => emit(GoalError(f.message)),
      (goals) => emit(GoalLoaded(goals: goals)),
    );
  }

  void _onMilestoneAcknowledged(
      MilestoneAcknowledged event, Emitter<GoalState> emit) {
    if (state is GoalLoaded) {
      emit((state as GoalLoaded).clearMilestone());
    }
  }
}
