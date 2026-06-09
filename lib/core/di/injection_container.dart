import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/report/data/datasources/report_local_datasource.dart';
import 'package:penyintas_app/features/report/data/datasources/report_remote_datasource.dart';
import 'package:penyintas_app/features/report/data/repositories/report_repository_impl.dart';
import 'package:penyintas_app/features/report/domain/repositories/report_repository.dart';
import 'package:penyintas_app/features/report/domain/usecases/get_ai_insight_usecase.dart';
import 'package:penyintas_app/features/report/domain/usecases/get_monthly_report_usecase.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_bloc.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:penyintas_app/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:penyintas_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:penyintas_app/features/notification/domain/usecases/cancel_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/request_permission_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/save_fcm_token_usecase.dart';
import 'package:penyintas_app/features/notification/domain/usecases/schedule_daily_reminder_usecase.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/routing/app_router.dart';
import 'package:penyintas_app/core/routing/onboarding_guard.dart';
import 'package:penyintas_app/core/utils/analytics_service.dart';
import 'package:penyintas_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:penyintas_app/features/auth/data/datasources/user_settings_remote_datasource.dart';
import 'package:penyintas_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:penyintas_app/features/auth/data/repositories/user_settings_repository_impl.dart';
import 'package:penyintas_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:penyintas_app/features/auth/domain/repositories/user_settings_repository.dart';
import 'package:penyintas_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/push_user_settings_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sync_user_settings_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/wipe_local_data_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:penyintas_app/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:penyintas_app/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:penyintas_app/features/onboarding/domain/usecases/calculate_daily_budget_usecase.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_local_datasource.dart';
import 'package:penyintas_app/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:penyintas_app/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/budget/domain/usecases/delete_budget_limit_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_limits_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_overview_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/get_budget_settings_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/save_budget_limit_usecase.dart';
import 'package:penyintas_app/features/budget/domain/usecases/save_budget_settings_usecase.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_settings_bloc.dart';
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
import 'package:penyintas_app/features/survival/data/datasources/survival_local_datasource.dart';
import 'package:penyintas_app/features/survival/data/datasources/survival_remote_datasource.dart';
import 'package:penyintas_app/features/survival/data/repositories/survival_repository_impl.dart';
import 'package:penyintas_app/features/survival/domain/repositories/survival_repository.dart';
import 'package:penyintas_app/features/survival/domain/usecases/clear_survival_activated_usecase.dart';
import 'package:penyintas_app/features/survival/domain/usecases/get_survival_mode_usecase.dart';
import 'package:penyintas_app/features/survival/domain/usecases/get_survival_tips_usecase.dart';
import 'package:penyintas_app/features/survival/domain/usecases/record_survival_activated_usecase.dart';
import 'package:penyintas_app/features/goal/data/datasources/goal_local_datasource.dart';
import 'package:penyintas_app/features/goal/data/repositories/goal_repository_impl.dart';
import 'package:penyintas_app/features/goal/domain/repositories/goal_repository.dart';
import 'package:penyintas_app/features/goal/domain/usecases/complete_goal_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/create_goal_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/delete_goal_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/link_transaction_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/load_goals_usecase.dart';
import 'package:penyintas_app/features/goal/domain/usecases/unlink_transaction_usecase.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/create_category_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/delete_category_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_categories_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_limitable_categories_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/update_category_usecase.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/category_repository.dart';
import 'package:penyintas_app/features/transaction/data/datasources/category_local_datasource.dart';
import 'package:penyintas_app/features/transaction/data/repositories/category_repository_impl.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/category_bloc.dart';

final sl = GetIt.instance;

Future<void> init({required AppDatabase db}) async {
  _registerExternal(db);
  _registerCore();
  _registerSettings();
  _initAuth();
  _initOnboarding();
  _initTransaction();
  _initCategory(); // harus sebelum _initBudget (BudgetLimitsBloc depends on GetLimitableCategoriesUseCase)
  _initBudget();
  _initDashboard();
  _initSync();
  _initNotification();
  _initReport();
  _initSurvival();
  _initGoal();
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
  sl.registerLazySingleton<GoRouter>(() => createAppRouter());
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
        wipeLocalData: sl(),
        deleteAccount: sl(),
        sendPasswordReset: sl(),
      ));

  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => WatchAuthStateUseCase(sl()));

  sl.registerLazySingleton(() => WipeLocalDataUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetUseCase(sl()));
  sl.registerLazySingleton(() => SyncUserSettingsUseCase(sl()));
  sl.registerLazySingleton(() => PushUserSettingsUseCase(sl()));

  sl.registerLazySingleton<UserSettingsRepository>(
    () => UserSettingsRepositoryImpl(db: sl(), remote: sl()),
  );
  sl.registerLazySingleton<UserSettingsRemoteDatasource>(
    () => UserSettingsRemoteDatasourceImpl(auth: sl(), firestore: sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(auth: sl(), firestore: sl(), functions: sl()),
  );
}

void _initOnboarding() {
  sl.registerFactory(() => OnboardingBloc(
        saveBudgetSettings: sl(),
        calculateDailyBudget: sl(),
        analyticsService: sl(),
        pushUserSettings: sl(),
      ));

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
  sl.registerLazySingleton<OnboardingGuard>(
    () => OnboardingGuard(sl<OnboardingLocalDataSource>()),
  );
  sl.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(
      auth: sl(),
      firestore: sl(),
      crashlytics: FirebaseCrashlytics.instance,
    ),
  );
}

void _initTransaction() {
  sl.registerFactory(
    () => AddTransactionBloc(
      addTransaction: sl(),
      getCategories: sl(),
    ),
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

void _initCategory() {
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetLimitableCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => CreateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCategoryUseCase(sl()));

  sl.registerFactory(() => CategoryBloc(
    getCategories: sl(),
    createCategory: sl(),
    updateCategory: sl(),
    deleteCategory: sl(),
  ));

  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CategoryLocalDatasource>(
    () => CategoryLocalDatasourceImpl(sl()),
  );
}

void _initBudget() {
  sl.registerFactory(() => BudgetSettingsBloc(
        getBudgetSettings: sl(),
        saveBudgetSettings: sl(),
      ));
  sl.registerFactory(() => BudgetLimitsBloc(
        getBudgetSettings: sl(),
        getBudgetLimits: sl(),
        saveBudgetLimit: sl(),
        deleteBudgetLimit: sl(),
        getBudgetOverview: sl(),
        transactionRepository: sl(),
        getLimitableCategories: sl(),
      ));

  sl.registerLazySingleton(() => GetBudgetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => SaveBudgetSettingsUseCase(sl()));
  sl.registerLazySingleton(() => GetBudgetLimitsUseCase(sl()));
  sl.registerLazySingleton(() => SaveBudgetLimitUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBudgetLimitUseCase(sl()));
  sl.registerLazySingleton<GetBudgetOverviewUseCase>(() => const GetBudgetOverviewUseCase());

  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      local: sl(),
      remote: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<BudgetLocalDatasource>(
    () => BudgetLocalDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<BudgetRemoteDatasource>(
    () => BudgetRemoteDatasourceImpl(auth: sl(), firestore: sl()),
  );
}

void _initDashboard() {
  // lazySingleton — instance yang sama dipakai di DashboardPage dan router.
  // registerFactory akan membuat instance baru setiap pageBuilder dipanggil
  // (mis. saat context.push), yang menyebabkan state reset ke DashboardInitial
  // dan loading indicator muncul saat kembali ke dashboard.
  sl.registerLazySingleton(() => DashboardBloc(getDashboard: sl()));

  sl.registerLazySingleton(() => GetDashboardUseCase(sl()));
  sl.registerLazySingleton(() => const CalculateDaysToLiveUseCase());

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      transactionRepository: sl(),
      budgetRepository: sl(),
      calculateDtl: sl(),
    ),
  );
}

void _initReport() {
  sl.registerFactory(() => ReportBloc(
        getMonthlyReport: sl(),
        getAiInsight: sl(),
      ));

  sl.registerLazySingleton(() => GetMonthlyReportUseCase(sl()));
  sl.registerLazySingleton(() => GetAiInsightUseCase(sl()));

  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(local: sl(), remote: sl(), db: sl()),
  );

  sl.registerLazySingleton<ReportLocalDatasource>(
    () => ReportLocalDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<ReportRemoteDatasource>(
    () => ReportRemoteDatasourceImpl(
          functions: sl(),
          firestore: sl(),
          auth: sl(),
        ),
  );
}

void _initNotification() {
  sl.registerFactory(() => NotificationBloc(
        requestPermission: sl(),
        saveFcmToken: sl(),
        scheduleDailyReminder: sl(),
        cancelDailyReminder: sl(),
        messaging: sl(),
        auth: sl(),
        local: sl(),
        db: sl(),
      ));

  sl.registerLazySingleton(() => RequestPermissionUseCase(sl()));
  sl.registerLazySingleton(() => SaveFcmTokenUseCase(sl()));
  sl.registerLazySingleton(() => ScheduleDailyReminderUseCase(sl()));
  sl.registerLazySingleton(() => CancelDailyReminderUseCase(sl()));

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(local: sl(), remote: sl()),
  );

  sl.registerLazySingleton<NotificationLocalDatasource>(
    () => NotificationLocalDatasourceImpl(),
  );
  sl.registerLazySingleton<NotificationRemoteDatasource>(
    () => NotificationRemoteDatasourceImpl(messaging: sl(), firestore: sl()),
  );
}

void _initGoal() {
  // Singleton — instance yang sama dipakai di GoalListPage, GoalDetailPage,
  // dan dipicu reload dari Dashboard/TransactionList/Profile setelah save
  sl.registerLazySingleton(() => GoalBloc(
        loadGoals: sl(),
        createGoal: sl(),
        linkTransaction: sl(),
        unlinkTransaction: sl(),
        completeGoal: sl(),
        deleteGoal: sl(),
      ));

  sl.registerLazySingleton(() => LoadGoalsUseCase(sl()));
  sl.registerLazySingleton(() => CreateGoalUseCase(sl()));
  sl.registerLazySingleton(() => LinkTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UnlinkTransactionUseCase(sl()));
  sl.registerLazySingleton(() => CompleteGoalUseCase(sl()));
  sl.registerLazySingleton(() => DeleteGoalUseCase(sl()));

  sl.registerLazySingleton<GoalRepository>(
    () => GoalRepositoryImpl(local: sl()),
  );

  sl.registerLazySingleton<GoalLocalDatasource>(
    () => GoalLocalDatasourceImpl(sl()),
  );
}

void _initSurvival() {
  // Singleton — tips ter-cache in-memory selama sesi, persist antar navigasi
  sl.registerLazySingleton(() => SurvivalBloc(
        getSurvivalMode: sl(),
        getSurvivalTips: sl(),
        recordActivated: sl(),
        clearActivated: sl(),
      ));

  sl.registerLazySingleton(() => GetSurvivalModeUseCase(sl()));
  sl.registerLazySingleton(() => GetSurvivalTipsUseCase(sl()));
  sl.registerLazySingleton(() => RecordSurvivalActivatedUseCase(sl()));
  sl.registerLazySingleton(() => ClearSurvivalActivatedUseCase(sl()));

  sl.registerLazySingleton<SurvivalRepository>(
    () => SurvivalRepositoryImpl(local: sl(), remote: sl()),
  );

  sl.registerLazySingleton<SurvivalLocalDatasource>(
    () => SurvivalLocalDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<SurvivalRemoteDatasource>(
    () => SurvivalRemoteDatasourceImpl(functions: sl()),
  );
}
