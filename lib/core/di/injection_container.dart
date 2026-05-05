import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/utils/analytics_service.dart';
import 'package:penyintas_app/features/settings/presentation/bloc/settings_bloc.dart';

final sl = GetIt.instance;

Future<void> init({required Isar isar}) async {
  _registerExternal(isar);
  _registerCore();
  _registerSettings();
}

void _registerExternal(Isar isar) {
  // ── Isar ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<Isar>(() => isar);

  // ── Firebase ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => FirebaseAnalytics.instance);
  sl.registerLazySingleton(() => FirebaseRemoteConfig.instance);
  sl.registerLazySingleton(() => FirebaseFunctions.instance);
  sl.registerLazySingleton(() => FirebasePerformance.instance);

  // ── Connectivity ─────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => Connectivity());
}

void _registerCore() {
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );
  sl.registerLazySingleton(
    () => AnalyticsService(sl()),
  );
}

void _registerSettings() {
  sl.registerFactory(() => SettingsBloc(sl()));
}
