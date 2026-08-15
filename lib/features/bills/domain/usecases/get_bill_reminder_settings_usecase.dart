import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_settings_datasource.dart';

/// Baca setelan pengingat tagihan GLOBAL lewat lapisan domain.
///
/// Ada supaya form tagihan tak memanggil datasource langsung dari
/// `presentation/` (spec §6.5). Hanya jalur BACA — jalur tulis
/// (`updateBillReminderSettings`) masih menunggu layar pengaturannya, yang
/// sengaja di luar scope.
class GetBillReminderSettingsUseCase
    implements UseCase<BillReminderSettings, NoParams> {
  const GetBillReminderSettingsUseCase(this._datasource);

  final BillReminderSettingsDatasource _datasource;

  @override
  Future<Either<Failure, BillReminderSettings>> call(NoParams params) async {
    try {
      return Right(await _datasource.read());
    } catch (e) {
      // `read()` sendiri punya fallback dan tak melempar untuk baris yang
      // hilang — yang tertangkap di sini adalah kegagalan DB sungguhan.
      // Pemanggil memperlakukan Left sama dengan "belum tiba": chip Bawaan
      // tampil tanpa baris bawah, form tetap jalan.
      return Left(CacheFailure(e.toString()));
    }
  }
}
