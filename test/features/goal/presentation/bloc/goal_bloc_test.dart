import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/domain/usecases/complete_goal_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/create_goal_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/delete_goal_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/link_transaction_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/load_goals_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/unlink_transaction_usecase.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockLoadGoalsUseCase extends Mock implements LoadGoalsUseCase {}

class MockCreateGoalUseCase extends Mock implements CreateGoalUseCase {}

class MockLinkTransactionUseCase extends Mock
    implements LinkTransactionUseCase {}

class MockUnlinkTransactionUseCase extends Mock
    implements UnlinkTransactionUseCase {}

class MockCompleteGoalUseCase extends Mock implements CompleteGoalUseCase {}

class MockDeleteGoalUseCase extends Mock implements DeleteGoalUseCase {}

// ── Helpers ───────────────────────────────────────────────────────────────────

GoalEntity _makeGoal({
  int id = 1,
  String title = 'Pulang kampung',
  int targetAmount = 1000000,
  int savedAmount = 0,
  bool isCompleted = false,
}) => GoalEntity(
  id: id,
  title: title,
  targetAmount: targetAmount,
  savedAmount: savedAmount,
  targetDate: DateTime(2026, 12, 31),
  isCompleted: isCompleted,
  createdAt: DateTime(2026, 5, 21),
);

GoalBloc _makeBloc({
  required MockLoadGoalsUseCase load,
  required MockCreateGoalUseCase create,
  required MockLinkTransactionUseCase link,
  required MockUnlinkTransactionUseCase unlink,
  required MockCompleteGoalUseCase complete,
  required MockDeleteGoalUseCase delete,
}) => GoalBloc(
  loadGoals: load,
  createGoal: create,
  linkTransaction: link,
  unlinkTransaction: unlink,
  completeGoal: complete,
  deleteGoal: delete,
);

void main() {
  late MockLoadGoalsUseCase mockLoad;
  late MockCreateGoalUseCase mockCreate;
  late MockLinkTransactionUseCase mockLink;
  late MockUnlinkTransactionUseCase mockUnlink;
  late MockCompleteGoalUseCase mockComplete;
  late MockDeleteGoalUseCase mockDelete;

  setUp(() {
    mockLoad = MockLoadGoalsUseCase();
    mockCreate = MockCreateGoalUseCase();
    mockLink = MockLinkTransactionUseCase();
    mockUnlink = MockUnlinkTransactionUseCase();
    mockComplete = MockCompleteGoalUseCase();
    mockDelete = MockDeleteGoalUseCase();

    registerFallbackValue(const NoParams());
    registerFallbackValue(
      CreateGoalParams(
        title: 'x',
        targetAmount: 1,
        targetDate: DateTime(2026, 12, 31),
      ),
    );
    registerFallbackValue(const LinkTransactionParams(txId: 'x', goalId: 1));
  });

  // ── LoadGoals ─────────────────────────────────────────────────────────────

  group('LoadGoals', () {
    final goals = [_makeGoal()];

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalLoaded] on success',
      build: () {
        when(() => mockLoad(any())).thenAnswer((_) async => Right(goals));
        return _makeBloc(
          load: mockLoad,
          create: mockCreate,
          link: mockLink,
          unlink: mockUnlink,
          complete: mockComplete,
          delete: mockDelete,
        );
      },
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [const GoalLoading(), GoalLoaded(goals: goals)],
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] on failure',
      build: () {
        when(
          () => mockLoad(any()),
        ).thenAnswer((_) async => Left(CacheFailure('db error')));
        return _makeBloc(
          load: mockLoad,
          create: mockCreate,
          link: mockLink,
          unlink: mockUnlink,
          complete: mockComplete,
          delete: mockDelete,
        );
      },
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [const GoalLoading(), const GoalError('db error')],
    );

    blocTest<GoalBloc, GoalState>(
      'emits GoalLoaded with empty list when no goals exist',
      build: () {
        when(() => mockLoad(any())).thenAnswer((_) async => const Right([]));
        return _makeBloc(
          load: mockLoad,
          create: mockCreate,
          link: mockLink,
          unlink: mockUnlink,
          complete: mockComplete,
          delete: mockDelete,
        );
      },
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [const GoalLoading(), const GoalLoaded(goals: [])],
    );
  });

  // ── CreateGoal ────────────────────────────────────────────────────────────

  group('CreateGoal', () {
    final targetDate = DateTime(2026, 12, 31);
    final goals = [_makeGoal(title: 'Beli laptop', targetAmount: 5000000)];

    blocTest<GoalBloc, GoalState>(
      'emits [GoalActionLoading, GoalLoaded] on success',
      build: () {
        when(
          () => mockCreate(any()),
        ).thenAnswer((_) async => const Right(null));
        when(() => mockLoad(any())).thenAnswer((_) async => Right(goals));
        return _makeBloc(
          load: mockLoad,
          create: mockCreate,
          link: mockLink,
          unlink: mockUnlink,
          complete: mockComplete,
          delete: mockDelete,
        );
      },
      seed: () => const GoalLoaded(goals: []),
      act: (bloc) => bloc.add(
        CreateGoal(
          title: 'Beli laptop',
          targetAmount: 5000000,
          targetDate: targetDate,
        ),
      ),
      expect: () => [const GoalActionLoading([]), GoalLoaded(goals: goals)],
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalActionLoading, GoalError] when create fails',
      build: () {
        when(
          () => mockCreate(any()),
        ).thenAnswer((_) async => Left(CacheFailure('write error')));
        return _makeBloc(
          load: mockLoad,
          create: mockCreate,
          link: mockLink,
          unlink: mockUnlink,
          complete: mockComplete,
          delete: mockDelete,
        );
      },
      seed: () => const GoalLoaded(goals: []),
      act: (bloc) => bloc.add(
        CreateGoal(
          title: 'Beli laptop',
          targetAmount: 5000000,
          targetDate: targetDate,
        ),
      ),
      expect: () => [
        const GoalActionLoading([]),
        const GoalError('write error'),
      ],
    );
  });

  // ── LinkTransaction ───────────────────────────────────────────────────────

  group('LinkTransaction', () {
    final goalBefore = _makeGoal(targetAmount: 1000000, savedAmount: 0);
    final goalAfterCross25 = _makeGoal(
      targetAmount: 1000000,
      savedAmount: 250000,
    );

    blocTest<GoalBloc, GoalState>(
      'emits GoalLoaded with milestoneGoalId when 25% threshold crossed',
      build: () {
        when(() => mockLink(any())).thenAnswer((_) async => const Right(null));
        when(
          () => mockLoad(any()),
        ).thenAnswer((_) async => Right([goalAfterCross25]));
        return _makeBloc(
          load: mockLoad,
          create: mockCreate,
          link: mockLink,
          unlink: mockUnlink,
          complete: mockComplete,
          delete: mockDelete,
        );
      },
      seed: () => GoalLoaded(goals: [goalBefore]),
      act: (bloc) => bloc.add(const LinkTransaction(txId: 'tx-1', goalId: 1)),
      expect: () => [
        GoalActionLoading([goalBefore]),
        GoalLoaded(
          goals: [goalAfterCross25],
          milestoneGoalId: 1,
          milestoneThreshold: 0.25,
        ),
      ],
    );

    blocTest<GoalBloc, GoalState>(
      'emits GoalLoaded without milestone when no threshold crossed',
      build: () {
        final goalAfter = _makeGoal(targetAmount: 1000000, savedAmount: 100000);
        when(() => mockLink(any())).thenAnswer((_) async => const Right(null));
        when(() => mockLoad(any())).thenAnswer((_) async => Right([goalAfter]));
        return _makeBloc(
          load: mockLoad,
          create: mockCreate,
          link: mockLink,
          unlink: mockUnlink,
          complete: mockComplete,
          delete: mockDelete,
        );
      },
      seed: () => GoalLoaded(goals: [goalBefore]),
      act: (bloc) => bloc.add(const LinkTransaction(txId: 'tx-1', goalId: 1)),
      expect: () => [
        GoalActionLoading([goalBefore]),
        GoalLoaded(
          goals: [_makeGoal(targetAmount: 1000000, savedAmount: 100000)],
        ),
      ],
    );
  });

  // ── MilestoneAcknowledged ─────────────────────────────────────────────────

  group('MilestoneAcknowledged', () {
    final goals = [_makeGoal(savedAmount: 250000)];

    blocTest<GoalBloc, GoalState>(
      'clears milestoneGoalId after acknowledge',
      build: () => _makeBloc(
        load: mockLoad,
        create: mockCreate,
        link: mockLink,
        unlink: mockUnlink,
        complete: mockComplete,
        delete: mockDelete,
      ),
      seed: () => GoalLoaded(
        goals: goals,
        milestoneGoalId: 1,
        milestoneThreshold: 0.25,
      ),
      act: (bloc) => bloc.add(const MilestoneAcknowledged()),
      expect: () => [GoalLoaded(goals: goals)],
    );
  });

  // ── DeleteGoal ────────────────────────────────────────────────────────────

  group('DeleteGoal', () {
    final goals = [_makeGoal(id: 1), _makeGoal(id: 2, title: 'Lainnya')];

    blocTest<GoalBloc, GoalState>(
      'emits GoalLoaded with goal removed after delete',
      build: () {
        when(
          () => mockDelete(any()),
        ).thenAnswer((_) async => const Right(null));
        when(() => mockLoad(any())).thenAnswer((_) async => Right([goals[1]]));
        return _makeBloc(
          load: mockLoad,
          create: mockCreate,
          link: mockLink,
          unlink: mockUnlink,
          complete: mockComplete,
          delete: mockDelete,
        );
      },
      seed: () => GoalLoaded(goals: goals),
      act: (bloc) => bloc.add(const DeleteGoal(1)),
      expect: () => [
        GoalActionLoading(goals),
        GoalLoaded(goals: [goals[1]]),
      ],
    );
  });
}
