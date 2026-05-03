import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
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
      builder: (context, state) => const _PlaceholderPage(title: 'Onboarding'),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const _PlaceholderPage(title: 'Dashboard'),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const _PlaceholderPage(title: 'Transactions'),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const _PlaceholderPage(title: 'Add Transaction'),
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
