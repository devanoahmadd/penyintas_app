import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/local/app_settings_isar_model.dart';
import 'package:penyintas_app/core/routing/go_router_refresh_stream.dart';
import 'package:penyintas_app/features/auth/presentation/pages/login_page.dart';
import 'package:penyintas_app/features/auth/presentation/pages/register_page.dart';
import 'package:penyintas_app/features/auth/presentation/pages/splash_page.dart';
import 'package:penyintas_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:penyintas_app/features/onboarding/presentation/pages/onboarding_page.dart';

final appRouter = GoRouter(
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
      builder: (context, state) => const _PlaceholderPage(title: 'Dashboard'),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) =>
          const _PlaceholderPage(title: 'Transactions'),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) =>
              const _PlaceholderPage(title: 'Add Transaction'),
        ),
      ],
    ),
    GoRoute(
      path: '/budget',
      builder: (context, state) => const _PlaceholderPage(title: 'Budget'),
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) => const _PlaceholderPage(title: 'Report'),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const _PlaceholderPage(title: 'Settings'),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const _PlaceholderPage(title: 'Profile'),
    ),
  ],
);

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final user = FirebaseAuth.instance.currentUser;
  final location = state.uri.path;

  const publicRoutes = ['/splash', '/login', '/register'];

  if (user == null) {
    return publicRoutes.contains(location) ? null : '/login';
  }

  final isar = sl<Isar>();
  final settings = await isar.appSettingsIsarModels.get(1);
  final onboardingDone = settings?.onboardingCompleted ?? false;

  if (!onboardingDone && location != '/onboarding') {
    return '/onboarding';
  }

  if (publicRoutes.contains(location) || location == '/onboarding') {
    return '/dashboard';
  }

  return null;
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
