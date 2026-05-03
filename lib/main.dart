import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:penyintas_app/app.dart';
import 'package:penyintas_app/core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    // Phase 1: tambahkan [TransactionSchema, AppSettingsSchema, SyncQueueSchema]
    [],
    directory: dir.path,
  );

  await di.init(isar: isar);

  runApp(const PenyintasApp());
}
