import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/routing/bootstrap_coordinator.dart';
import 'package:penyintas_app/core/routing/onboarding_guard.dart';
import 'package:penyintas_app/core/routing/onboarding_status.dart';
import 'package:penyintas_app/core/routing/go_router_refresh_stream.dart';
import 'package:penyintas_app/features/auth/presentation/pages/login_page.dart';
import 'package:penyintas_app/features/auth/presentation/pages/register_page.dart';
import 'package:penyintas_app/features/auth/presentation/pages/splash_page.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:penyintas_app/features/onboarding/presentation/cubit/onboarding_draft_cubit.dart';
import 'package:penyintas_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:penyintas_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:penyintas_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:penyintas_app/features/survival/presentation/bloc/survival_bloc.dart';
import 'package:penyintas_app/features/survival/presentation/pages/survival_tips_page.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_bloc.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_event.dart';
import 'package:penyintas_app/features/report/presentation/pages/report_page.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';
import 'package:penyintas_app/features/settings/presentation/pages/settings_page.dart';
import 'package:penyintas_app/features/goal/domain/entities/goal_entity.dart';
import 'package:penyintas_app/features/goal/presentation/bloc/goal_bloc.dart';
import 'package:penyintas_app/features/goal/presentation/pages/goal_detail_page.dart';
import 'package:penyintas_app/features/goal/presentation/pages/goal_list_page.dart';
import 'package:penyintas_app/features/profile/presentation/pages/saya_page.dart';
import 'package:penyintas_app/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:penyintas_app/features/transaction/presentation/pages/transaction_list_page.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'package:penyintas_app/features/budget/presentation/bloc/budget_settings_bloc.dart';
import 'package:penyintas_app/features/budget/presentation/pages/budget_edit_settings_page.dart';
import 'package:penyintas_app/features/budget/presentation/pages/budget_overview_page.dart';
import 'package:penyintas_app/features/budget/presentation/pages/manage_categories_page.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/category_bloc.dart';
import 'package:penyintas_app/features/onboarding/presentation/cubit/profile_setup_cubit.dart';
import 'package:penyintas_app/features/onboarding/presentation/pages/profile_leg_page.dart';
import 'package:penyintas_app/features/preferences/presentation/cubit/timezone_reconciliation_cubit.dart';

GoRouter createAppRouter() => GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: _redirect,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<OnboardingBloc>()),
          BlocProvider(create: (_) => sl<OnboardingDraftCubit>()),
        ],
        child: const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<ProfileSetupCubit>(),
        child: const ProfileLegPage(),
      ),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: MultiBlocProvider(
          providers: [
            // .value — jangan close singleton saat route di-pop/replace
            BlocProvider.value(value: sl<DashboardBloc>()),
            BlocProvider.value(value: sl<SurvivalBloc>()),
            BlocProvider.value(value: sl<BudgetLimitsBloc>()..add(const LoadBudgetLimits())),
            // F-D6: lazySingleton — .value agar snooze tetap hidup lintas-remount
            BlocProvider.value(value: sl<TimezoneReconciliationCubit>()),
          ],
          child: const DashboardPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/survival/tips',
      builder: (context, state) => BlocProvider.value(
        value: sl<SurvivalBloc>(),
        child: const SurvivalTipsPage(),
      ),
    ),
    GoRoute(
      path: '/transactions',
      pageBuilder: (context, state) {
        final now = DateTime.now();
        return NoTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => sl<TransactionListBloc>()
              ..add(LoadTransactions(
                from: DateTime(now.year, now.month, 1),
                to: now,
              )),
            child: const TransactionListPage(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/goals',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        // BlocProvider.value karena GoalBloc adalah singleton — jangan di-close
        // saat route di-pop agar state tetap hidup untuk reload cross-route
        child: BlocProvider.value(
          value: sl<GoalBloc>(),
          child: const GoalListPage(),
        ),
      ),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final goal = state.extra as GoalEntity;
            return BlocProvider.value(
              value: sl<GoalBloc>(),
              child: GoalDetailPage(goal: goal),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/budget',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => sl<BudgetSettingsBloc>()..add(const LoadBudgetSettings()),
            ),
            BlocProvider.value(
              value: sl<BudgetLimitsBloc>()..add(const LoadBudgetLimits()),
            ),
          ],
          child: const BudgetOverviewPage(),
        ),
      ),
      routes: [
        GoRoute(
          path: 'edit-settings',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => sl<BudgetSettingsBloc>()..add(const LoadBudgetSettings()),
              child: const BudgetEditSettingsPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'categories',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<CategoryBloc>()..add(const LoadCategories()),
            child: const ManageCategoriesPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/report',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<ReportBloc>()..add(LoadReport(DateTime.now())),
          child: const ReportPage(),
        ),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const SayaPage()),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const ProfileEditPage(),
    ),
  ],
);

/// Invalidasi cache onboarding agar `_redirect` query DB ulang.
/// Dipanggil SplashPage setelah sync menulis nilai baru ke Drift (#192).
/// Masih dipakai onboarding_page.dart & profile_leg_page.dart.
void resetOnboardingCache() => sl<OnboardingGuard>().resetCache();

/// Rute publik (tanpa auth). Top-level (T-3) agar dipakai bersama `_redirect`
/// dan `redirectForAuthedUser`.
const publicRoutes = ['/splash', '/login', '/register'];

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final location = state.uri.path;

    // SplashPage mengontrol timingnya sendiri — jangan interrupt
    if (location == '/splash') return null;

    if (user == null) {
      sl<OnboardingGuard>().resetCache(); // reset saat logout
      sl<BootstrapCoordinator>().reset(); // Temuan 1: bootstrap fresh utk user berikutnya
      return publicRoutes.contains(location) ? null : '/login';
    }

    return redirectForAuthedUser(location); // Temuan 1/T-3: gate + guard (dapat diuji)
  } catch (e, stack) {
    FirebaseCrashlytics.instance.recordError(e, stack);
    return '/login';
  }
}

/// Cabang redirect user terautentikasi. Diekstrak agar **dapat diuji tanpa**
/// `FirebaseAuth.instance` (T-3). WAJIB `await ensure()` SEBELUM `guard.status()`:
/// memo per-sesi (jalan sekali), `ensure()` me-reset cache guard di akhir →
/// guard membaca state ter-bootstrap (tutup jalur fresh-login/reinstall, Temuan 1).
Future<String?> redirectForAuthedUser(String location) async {
  await sl<BootstrapCoordinator>().ensure();
  final status = await sl<OnboardingGuard>().status();
  switch (status) {
    case OnboardingStatus.needsProfile:
      return location == '/profile-setup' ? null : '/profile-setup';
    case OnboardingStatus.needsBudget:
      return location == '/onboarding' ? null : '/onboarding';
    case OnboardingStatus.done:
      if (publicRoutes.contains(location) ||
          location == '/onboarding' ||
          location == '/profile-setup') {
        return '/dashboard';
      }
      return null;
  }
}
