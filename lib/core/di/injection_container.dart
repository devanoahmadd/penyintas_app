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
import 'package:penyintas_app/core/database/app_database.dart';
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
import 'package:penyintas_app/features/transaction/data/datasources/transaction_local_datasource.dart';
import 'package:penyintas_app/features/transaction/data/datasources/transaction_remote_datasource.dart';
import 'package:penyintas_app/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/add_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_transactions_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/update_transaction_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/watch_today_transactions_usecase.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/add_transaction_bloc.dart';
import 'package:penyintas_app/core/sync/sync_service.dart';
import 'package:penyintas_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:penyintas_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/calculate_days_to_live_usecase.dart';
import 'package:penyintas_app/features/dashboard/domain/usecases/get_dashboard_usecase.dart';
import 'package:penyintas_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';

final sl = GetIt.instance;

Future<void> init({required AppDatabase db}) async {
  _registerExternal(db);
  _registerCore();
  _registerSettings();
  _initAuth();
  _initOnboarding();
  _initTransaction();
  _initDashboard();
  _initSync();
}

void _registerExternal(AppDatabase db) {
  // ── Drift ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AppDatabase>(() => db);

  // ── Firebase ─────────────────────────────────────────────────────────────
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
  sl.registerFactory(() => SettingsBloc(sl<AppDatabase>()));
}

void _initAuth() {
  sl.registerFactory(() => AuthBloc(
        signIn: sl(),
        signUp: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
        watchAuthState: sl(),
      ));

  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => WatchAuthStateUseCase(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(auth: sl(), firestore: sl()),
  );
}

void _initOnboarding() {
  sl.registerFactory(() => OnboardingBloc(
        saveBudgetSettings: sl(),
        calculateDailyBudget: sl(),
        analyticsService: sl(),
      ));

  sl.registerLazySingleton(() => SaveBudgetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => GetBudgetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => CalculateDailyBudgetUseCase());

  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      auth: sl(),
    ),
  );

  sl.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(auth: sl(), firestore: sl()),
  );
}

void _initTransaction() {
  sl.registerFactory(
    () => AddTransactionBloc(addTransaction: sl()),
  );
  sl.registerFactory(
    () => TransactionListBloc(
      getTransactions: sl(),
      deleteTransaction: sl(),
    ),
  );

  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => WatchTodayTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));

  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      auth: sl(),
    ),
  );

  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(auth: sl(), firestore: sl()),
  );
}

void _initSync() {
  sl.registerLazySingleton(() => SyncService(
        db: sl(),
        networkInfo: sl(),
        auth: sl(),
        firestore: sl(),
      ));
}

void _initDashboard() {
  sl.registerFactory(() => DashboardBloc(getDashboard: sl()));

  sl.registerLazySingleton(() => GetDashboardUseCase(sl()));
  sl.registerLazySingleton(() => const CalculateDaysToLiveUseCase());

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      transactionRepository: sl(),
      onboardingRepository: sl(),
      calculateDtl: sl(),
    ),
  );
}
