import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/routing/go_router_refresh_stream.dart';
import 'package:penyintas_app/features/auth/presentation/pages/login_page.dart';
import 'package:penyintas_app/features/auth/presentation/pages/register_page.dart';
import 'package:penyintas_app/features/auth/presentation/pages/splash_page.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:penyintas_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:penyintas_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:penyintas_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_bloc.dart';
import 'package:penyintas_app/features/report/presentation/bloc/report_event.dart';
import 'package:penyintas_app/features/report/presentation/pages/report_page.dart';
import 'package:penyintas_app/features/transaction/presentation/bloc/transaction_list_bloc.dart';
import 'package:penyintas_app/features/settings/presentation/pages/settings_page.dart';
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
        child: BlocProvider(
          create: (_) => sl<DashboardBloc>(),
          child: const DashboardPage(),
        ),
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
      path: '/budget',
      builder: (context, state) => const _PlaceholderPage(title: 'Budget'),
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
      builder: (context, state) => const _PlaceholderPage(title: 'Profile'),
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

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
