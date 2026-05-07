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
import 'package:penyintas_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:penyintas_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:penyintas_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:penyintas_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:penyintas_app/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/calculate_daily_budget_usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/get_budget_settings_usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/save_budget_settings_usecase.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:penyintas_app/features/settings/presentation/bloc/settings_bloc.dart';

final sl = GetIt.instance;

Future<void> init({required Isar isar}) async {
  _registerExternal(isar);
  _registerCore();
  _registerSettings();
  _initAuth();
  _initOnboarding();
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

void _initAuth() {
  // BLoC — factory agar setiap halaman dapat instance bersih
  sl.registerFactory(() => AuthBloc(
        signIn: sl(),
        signUp: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
        watchAuthState: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => WatchAuthStateUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(auth: sl(), firestore: sl()),
  );
}

void _initOnboarding() {
  // BLoC
  sl.registerFactory(() => OnboardingBloc(
        saveBudgetSettings: sl(),
        calculateDailyBudget: sl(),
        analyticsService: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => SaveBudgetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => GetBudgetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => CalculateDailyBudgetUseCase());

  // Repository
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      auth: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(auth: sl(), firestore: sl()),
  );
}
