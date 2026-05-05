import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/local/app_settings_isar_model.dart';
import 'package:isar/isar.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: _redirect,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const _PlaceholderPage(title: 'Splash'),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const _PlaceholderPage(title: 'Login'),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const _PlaceholderPage(title: 'Register'),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) =>
          const _PlaceholderPage(title: 'Onboarding'),
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

// Redirect logic — Phase 2: sync check via FirebaseAuth + Isar.
// Phase 3: upgrade ke refreshListenable(GoRouterRefreshStream(authBloc.stream))
Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final user = FirebaseAuth.instance.currentUser;
  final location = state.uri.path;

  // Halaman publik: splash, login, register — tidak perlu redirect
  const publicRoutes = ['/splash', '/login', '/register'];

  if (user == null) {
    // Belum login → izinkan halaman publik, redirect sisanya ke login
    return publicRoutes.contains(location) ? null : '/login';
  }

  // Sudah login — cek onboarding
  final isar = sl<Isar>();
  final settings = await isar.appSettingsIsarModels.get(1);
  final onboardingDone = settings?.onboardingCompleted ?? false;

  if (!onboardingDone && location != '/onboarding') {
    return '/onboarding';
  }

  // Sudah onboarding — jangan balik ke halaman publik
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
