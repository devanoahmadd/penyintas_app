import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:penyintas_app/app.dart';
import 'package:penyintas_app/core/di/injection_container.dart' as di;
import 'package:penyintas_app/core/local/app_settings_isar_model.dart';
import 'package:penyintas_app/core/local/sync_queue_isar_model.dart';
import 'package:penyintas_app/features/transaction/data/models/transaction_isar_model.dart';
import 'package:penyintas_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ─────────────────────────────────────────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    // Ganti ke AndroidPlayIntegrityProvider() + AppleDeviceCheckProvider() untuk release
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleDebugProvider(),
  );

  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ── Isar ─────────────────────────────────────────────────────────────────
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      TransactionIsarModelSchema,
      AppSettingsIsarModelSchema,
      SyncQueueIsarModelSchema,
    ],
    directory: dir.path,
  );

  // ── Dependency Injection ──────────────────────────────────────────────────
  await di.init(isar: isar);

  runApp(const PenyintasApp());
}
