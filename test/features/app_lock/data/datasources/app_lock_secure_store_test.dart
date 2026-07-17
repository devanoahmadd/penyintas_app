import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/app_lock/data/datasources/app_lock_secure_store.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockStorage storage;
  late AppLockSecureStoreImpl store;

  setUp(() {
    storage = _MockStorage();
    store = AppLockSecureStoreImpl(storage);
  });

  test('read mendelegasikan ke FlutterSecureStorage', () async {
    when(
      () => storage.read(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async => 'v');

    final r = await store.read('k');

    expect(r, 'v');
    verify(
      () => storage.read(
        key: 'k',
        aOptions: any(named: 'aOptions'),
      ),
    ).called(1);
  });

  test('write mendelegasikan', () async {
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async {});

    await store.write('k', 'v');

    verify(
      () => storage.write(
        key: 'k',
        value: 'v',
        aOptions: any(named: 'aOptions'),
      ),
    ).called(1);
  });

  test('delete mendelegasikan', () async {
    when(
      () => storage.delete(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async {});

    await store.delete('k');

    verify(
      () => storage.delete(
        key: 'k',
        aOptions: any(named: 'aOptions'),
      ),
    ).called(1);
  });
}
