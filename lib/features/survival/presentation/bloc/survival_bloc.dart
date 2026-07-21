import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_mode_entity.dart';
import 'package:penyintas_app/features/survival/domain/usecases/clear_survival_activated_usecase.dart';
import 'package:penyintas_app/features/survival/domain/usecases/get_survival_mode_usecase.dart';
import 'package:penyintas_app/features/survival/domain/usecases/get_survival_tips_usecase.dart';
import 'package:penyintas_app/features/survival/domain/usecases/record_survival_activated_usecase.dart';

part 'survival_event.dart';
part 'survival_state.dart';

class SurvivalBloc extends Bloc<SurvivalEvent, SurvivalState> {
  SurvivalBloc({
    required GetSurvivalModeUseCase getSurvivalMode,
    required GetSurvivalTipsUseCase getSurvivalTips,
    required RecordSurvivalActivatedUseCase recordActivated,
    required ClearSurvivalActivatedUseCase clearActivated,
    Stream<String?>? uidChanges,
  }) : _getSurvivalMode = getSurvivalMode,
       _getSurvivalTips = getSurvivalTips,
       _recordActivated = recordActivated,
       _clearActivated = clearActivated,
       super(const SurvivalInitial()) {
    on<LoadSurvivalMode>(_onLoad, transformer: droppable());
    on<FetchSurvivalTips>(_onFetchTips, transformer: droppable());
    on<SurvivalSessionReset>(_onSessionReset);
    // distinct() SEBELUM skip(1) — urutan ini penting:
    //  · skip(1): authStateChanges emit user SAAT INI ke listener baru;
    //    emisi pertama = sesi berjalan, bukan pergantian akun.
    //  · distinct() lebih dulu agar token refresh (uid sama berulang) tidak
    //    lolos sebagai "nilai pertama" dan memicu reset palsu.
    // isClosed guard: stream bisa menyala setelah bloc ditutup (test/hot
    // restart) — add() ke bloc tertutup melempar StateError.
    _uidSub = uidChanges?.distinct().skip(1).listen((_) {
      if (!isClosed) add(const SurvivalSessionReset());
    });
  }

  StreamSubscription<String?>? _uidSub;

  /// Penanda sesi. Naik satu tiap kali sesi di-reset (logout / ganti akun).
  ///
  /// Dipakai operasi async panjang (fetch tips) untuk memastikan hasilnya masih
  /// milik sesi yang sama sebelum di-emit. `transformer: droppable()` TIDAK
  /// cukup: droppable hanya menyerialkan event bertipe sama, sedangkan
  /// [SurvivalSessionReset] bertipe lain dan handler-nya jalan concurrent.
  int _sessionEpoch = 0;

  final GetSurvivalModeUseCase _getSurvivalMode;
  final GetSurvivalTipsUseCase _getSurvivalTips;
  final RecordSurvivalActivatedUseCase _recordActivated;
  final ClearSurvivalActivatedUseCase _clearActivated;

  Future<void> _onLoad(
    LoadSurvivalMode event,
    Emitter<SurvivalState> emit,
  ) async {
    final result = await _getSurvivalMode(event.dashboard);
    if (result.isLeft()) {
      result.fold((f) => emit(SurvivalError(f.message)), (_) {});
      return;
    }
    final entity = result.getOrElse(() => throw StateError('unreachable'));

    if (!entity.isActive) {
      // Bersihkan timestamp saat keluar dari danger mode
      if (entity.activatedAt != null) await _clearActivated();
      emit(const SurvivalInactive());
    } else {
      // Catat waktu aktivasi pertama kali masuk danger mode
      if (entity.activatedAt == null) await _recordActivated();
      // Pertahankan tips/loading yang sudah ada saat dashboard refresh
      if (state is SurvivalTipsLoaded) {
        final cached = (state as SurvivalTipsLoaded).entity.tips;
        emit(SurvivalTipsLoaded(entity.copyWith(tips: cached)));
      } else if (state is SurvivalTipsLoading) {
        emit(SurvivalTipsLoading(entity));
      } else {
        emit(SurvivalActive(entity));
      }
    }
  }

  /// Reset sesi: buang state milik user lama sekaligus batalkan hasil fetch
  /// yang masih berjalan (lewat kenaikan [_sessionEpoch]).
  void _onSessionReset(
    SurvivalSessionReset event,
    Emitter<SurvivalState> emit,
  ) {
    _sessionEpoch++;
    emit(const SurvivalInitial());
  }

  Future<void> _onFetchTips(
    FetchSurvivalTips event,
    Emitter<SurvivalState> emit,
  ) async {
    // Tidak re-fetch jika tips sudah tersedia
    if (state is SurvivalTipsLoaded) return;

    SurvivalModeEntity? entity;
    if (state is SurvivalActive) {
      entity = (state as SurvivalActive).entity;
    } else if (state is SurvivalError) {
      entity = (state as SurvivalError).entity;
    }
    if (entity == null) return;

    // Rekam sesi saat ini SEBELUM await — hasil fetch hanya boleh di-emit
    // kalau sesinya belum berganti selama menunggu jawaban jaringan/AI.
    final epoch = _sessionEpoch;

    emit(SurvivalTipsLoading(entity));
    final result = await _getSurvivalTips(
      SurvivalTipsParams(
        remainingAmount: entity.remainingAmount,
        remainingDays: entity.remainingDays,
        language: event.language,
      ),
    );

    // Sesi sudah di-reset (logout / ganti akun) saat fetch berjalan — buang
    // hasilnya supaya tips user lama tidak menimpa SurvivalInitial (#152).
    if (epoch != _sessionEpoch) return;

    result.fold(
      (failure) => emit(SurvivalError(failure.message, entity)),
      (tips) => emit(SurvivalTipsLoaded(entity!.copyWith(tips: tips))),
    );
  }

  @override
  Future<void> close() async {
    await _uidSub?.cancel();
    return super.close();
  }
}
