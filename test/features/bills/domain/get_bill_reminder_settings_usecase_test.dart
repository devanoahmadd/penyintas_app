import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_settings_datasource.dart';
import 'package:penyintas_app/features/bills/domain/usecases/get_bill_reminder_settings_usecase.dart';

class MockDatasource extends Mock implements BillReminderSettingsDatasource {}

void main() {
  late MockDatasource ds;
  late GetBillReminderSettingsUseCase usecase;

  setUp(() {
    ds = MockDatasource();
    usecase = GetBillReminderSettingsUseCase(ds);
  });

  test('meneruskan setelan dari datasource', () async {
    when(() => ds.read()).thenAnswer((_) async => (daysBefore: 3, hour: 9));
    final hasil = await usecase(const NoParams());
    expect(
      hasil,
      const Right<Failure, BillReminderSettings>((daysBefore: 3, hour: 9)),
    );
  });

  test(
    'datasource melempar → Left(CacheFailure), bukan exception bocor',
    () async {
      when(() => ds.read()).thenThrow(Exception('db mati'));
      final hasil = await usecase(const NoParams());
      expect(hasil.isLeft(), isTrue);
      hasil.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('harus Left'),
      );
    },
  );
}
