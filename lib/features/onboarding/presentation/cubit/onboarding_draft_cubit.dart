import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/partial_onboarding_state.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/clear_partial_onboarding_usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/load_partial_onboarding_usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/save_partial_onboarding_usecase.dart';

part 'onboarding_draft_state.dart';

/// #242: memiliki partial-draft I/O onboarding, lepas dari OnboardingBloc
/// (submit pipeline). Page memakai ini via DI — bukan GetIt global.
class OnboardingDraftCubit extends Cubit<OnboardingDraftState> {
  OnboardingDraftCubit({
    required LoadPartialOnboardingUseCase loadDraft,
    required SavePartialOnboardingUseCase saveDraft,
    required ClearPartialOnboardingUseCase clearDraft,
  }) : _load = loadDraft,
       _save = saveDraft,
       _clear = clearDraft,
       super(const OnboardingDraftInitial());

  final LoadPartialOnboardingUseCase _load;
  final SavePartialOnboardingUseCase _save;
  final ClearPartialOnboardingUseCase _clear;

  /// Muat draft (dipanggil saat initState page). Gagal → loaded(null), tak crash.
  Future<void> loadDraft() async {
    final result = await _load(const NoParams());
    emit(OnboardingDraftLoaded(result.fold((_) => null, (partial) => partial)));
  }

  /// Simpan draft saat "Lanjut nanti". Fire-and-forget; kegagalan ditelan.
  Future<void> saveDraft({
    required int step,
    required int income,
    required Map<String, int> expenses,
    required int pct,
    required int payday,
  }) async {
    await _save(
      SavePartialParams(
        step: step,
        income: income,
        expenses: expenses,
        pct: pct,
        payday: payday,
      ),
    );
  }

  /// Hapus draft (reset / sukses onboarding). Kegagalan ditelan.
  Future<void> clearDraft() async {
    await _clear(const NoParams());
  }
}
