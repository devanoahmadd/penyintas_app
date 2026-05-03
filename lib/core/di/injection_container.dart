import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';

final sl = GetIt.instance;

Future<void> init({required Isar isar}) async {
  sl.registerLazySingleton<Isar>(() => isar);
  // Phase 1: Firebase + Isar collection services akan ditambahkan di sini
}
