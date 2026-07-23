import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/create_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/delete_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/update_bill_usecase.dart';
import 'package:penyintas_app/features/bills/domain/usecases/watch_active_bills_usecase.dart';

part 'bills_event.dart';
part 'bills_state.dart';

class BillsBloc extends Bloc<BillsEvent, BillsState> {
  BillsBloc({
    required WatchActiveBillsUseCase watchActiveBills,
    required CreateBillUseCase createBill,
    required UpdateBillUseCase updateBill,
    required DeleteBillUseCase deleteBill,
  }) : _watchActiveBills = watchActiveBills,
       _createBill = createBill,
       _updateBill = updateBill,
       _deleteBill = deleteBill,
       super(const BillsState()) {
    on<BillsSubscribed>(_onSubscribed, transformer: restartable());
    on<BillAdded>(_onAdded);
    on<BillUpdated>(_onUpdated);
    on<BillDeleted>(_onDeleted);
  }

  final WatchActiveBillsUseCase _watchActiveBills;
  final CreateBillUseCase _createBill;
  final UpdateBillUseCase _updateBill;
  final DeleteBillUseCase _deleteBill;

  static void _log(Object e, StackTrace s) {
    try {
      FirebaseCrashlytics.instance.recordError(e, s);
    } catch (_) {}
  }

  Future<void> _onSubscribed(
    BillsSubscribed event,
    Emitter<BillsState> emit,
  ) async {
    emit(state.copyWith(status: BillsStatus.loading));
    await emit.forEach<Either<Failure, List<BillEntity>>>(
      _watchActiveBills(const NoParams()),
      onData: (either) => either.fold(
        (f) => state.copyWith(status: BillsStatus.failure, failure: f),
        (bills) => state.copyWith(
          status: BillsStatus.success,
          bills: bills,
          clearFailure: true,
        ),
      ),
      onError: (e, s) {
        _log(e, s);
        return state.copyWith(
          status: BillsStatus.failure,
          failure: const CacheFailure('Gagal memuat tagihan.'),
        );
      },
    );
  }

  Future<void> _onAdded(BillAdded event, Emitter<BillsState> emit) async {
    final result = await _createBill(event.bill);
    result.fold(
      (f) => emit(state.copyWith(status: BillsStatus.failure, failure: f)),
      (_) {},
    );
    // sukses: stream watchActive akan re-emit daftar terbaru otomatis.
  }

  Future<void> _onUpdated(BillUpdated event, Emitter<BillsState> emit) async {
    final result = await _updateBill(event.bill);
    result.fold(
      (f) => emit(state.copyWith(status: BillsStatus.failure, failure: f)),
      (_) {},
    );
  }

  Future<void> _onDeleted(BillDeleted event, Emitter<BillsState> emit) async {
    final result = await _deleteBill(event.id);
    result.fold(
      (f) => emit(state.copyWith(status: BillsStatus.failure, failure: f)),
      (_) {},
    );
  }
}
