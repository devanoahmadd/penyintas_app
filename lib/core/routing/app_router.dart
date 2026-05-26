import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/routing/go_router_refresh_stream.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/widgets/common/app_bottom_nav_bar.dart';
import 'package:penyintas_app/features/auth/presentation/pages/login_page.dart';
import 'package:penyintas_app/features/auth/presentation/pages/register_page.dart';
import 'package:penyintas_app/features/auth/presentation/pages/splash_page.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
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
import 'package:penyintas_app/features/transaction/presentation/pages/transaction_list_page.dart';

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
      builder: (context, state) => BlocProvider(
        create: (_) => sl<OnboardingBloc>(),
        child: const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => NoTransitionPage(
        child: MultiBlocProvider(
          providers: [
            // .value — jangan close singleton saat route di-pop/replace
            BlocProvider.value(value: sl<DashboardBloc>()),
            BlocProvider.value(value: sl<SurvivalBloc>()),
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
      builder: (context, state) => const _BudgetComingSoonPage(),
    ),
    GoRoute(
      path: '/report',
      pageBuilder: (context, state) => NoTransitionPage(
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
          const NoTransitionPage(child: SayaPage()),
    ),
  ],
);

// Cache onboarding status — hindari DB query pada setiap navigasi
bool? _onboardingDone;

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final location = state.uri.path;

    // SplashPage mengontrol timingnya sendiri — jangan interrupt
    if (location == '/splash') return null;

    const publicRoutes = ['/splash', '/login', '/register'];

    if (user == null) {
      _onboardingDone = null; // reset saat logout
      return publicRoutes.contains(location) ? null : '/login';
    }

    // Query DB hanya sekali; setelah itu pakai cache
    _onboardingDone ??= await _queryOnboardingDone();

    if (!(_onboardingDone ?? false)) {
      return location == '/onboarding' ? null : '/onboarding';
    }

    if (publicRoutes.contains(location) || location == '/onboarding') {
      return '/dashboard';
    }

    return null;
  } catch (e, stack) {
    FirebaseCrashlytics.instance.recordError(e, stack);
    return '/login';
  }
}

Future<bool> _queryOnboardingDone() async {
  final db = sl<AppDatabase>();
  final settings = await (db.select(db.appSettings)
        ..where((t) => t.id.equals(1)))
      .getSingleOrNull();
  return settings?.onboardingCompleted ?? false;
}

class _BudgetComingSoonPage extends StatelessWidget {
  const _BudgetComingSoonPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    // inline import to avoid adding dependency in router file
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.budgetComingSoonEyebrow,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.budgetComingSoonTitle,
                  style: AppTextStyles.h2.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.budgetComingSoonBody,
                  style: AppTextStyles.body.copyWith(color: mutedColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        onFabTap: () {},
      ),
    );
  }
}
