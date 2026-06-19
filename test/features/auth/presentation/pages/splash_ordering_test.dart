// test/features/auth/presentation/pages/splash_ordering_test.dart
// F-D7 / Temuan 1: splash MENAHAN navigate sampai coordinator.ensure() resolve
// (kelas bug d4de2f2). Fake AuthBloc WAJIB emit TRANSISI ke Authenticated (Temuan 3).
import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/routing/bootstrap_coordinator.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/auth/presentation/pages/splash_page.dart';

class _MockCoordinator extends Mock implements BootstrapCoordinator {}
class _FakeAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

// CATATAN deviasi brief: `Authenticated` mengambil `UserEntity` (domain), bukan
// Firebase `User`. Brief verbatim memakai `_FakeUser implements User` → tak compile.
// Pakai UserEntity asli (pola sama dgn auth_bloc_test.dart `tUser`).
final _tUser = UserEntity(
  uid: 'uid-123',
  email: 'test@email.com',
  displayName: 'Tester',
  createdAt: DateTime(2025),
);

void main() {
  final sl = GetIt.instance; // sama dgn `sl` injection_container
  late _MockCoordinator coordinator;
  late _FakeAuthBloc authBloc;
  late Completer<void> syncGate; // gate ensure() agar bisa amati "sebelum navigate"
  final order = <String>[];

  setUp(() {
    order.clear();
    syncGate = Completer<void>();
    coordinator = _MockCoordinator();
    authBloc = _FakeAuthBloc();

    when(() => coordinator.ensure()).thenAnswer((_) async {
      order.add('ensure');
      await syncGate.future; // tahan sampai test melepas → amati "belum navigate"
    });
    sl.registerSingleton<BootstrapCoordinator>(coordinator);

    // Temuan 3: WAJIB emit TRANSISI (bukan mulai langsung di Authenticated) —
    // BlocListener splash tak fire untuk initial-state, hanya transisi.
    whenListen(
      authBloc,
      Stream<AuthState>.fromIterable([const AuthLoading(), Authenticated(_tUser)]),
      initialState: const AuthLoading(),
    );
  });
  tearDown(() => sl.reset());

  testWidgets('A2/F-D7: navigate ke /dashboard TERTUNDA sampai ensure() selesai', (t) async {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
        GoRoute(path: '/dashboard', builder: (_, _) {
          order.add('nav');
          return const SizedBox.shrink();
        }),
        GoRoute(path: '/login', builder: (_, _) => const SizedBox.shrink()),
      ],
    );
    await t.pumpWidget(MaterialApp.router(
      routerConfig: router,
      builder: (_, child) =>
          BlocProvider<AuthBloc>.value(value: authBloc, child: child!),
    ));

    await t.pump(); // proses stream → BlocListener → _syncThenNavigate → await ensure()
    await t.pump(const Duration(milliseconds: 2600)); // lewati branding gate (2500ms)
    expect(order, contains('ensure'));
    expect(order, isNot(contains('nav')),
        reason: 'navigate TAK boleh sebelum ensure() selesai (bug d4de2f2)');

    // DEVIASI brief: `pumpAndSettle()` kembali SEBELUM continuation microtask gate
    // ter-drain di splash nyata (interaksi fake-clock dgn timer RemoteConfig/animasi).
    // `runAsync` menjalankan di zona async NYATA → microtask `await ensure()` benar2
    // ter-flush, lalu pump untuk memproses `context.go('/dashboard')`.
    await t.runAsync(() async {
      syncGate.complete(); // bootstrap selesai
      await Future<void>.delayed(Duration.zero); // flush continuation `await ensure()`
    });
    await t.pump(); // go_router rebuild → /dashboard
    expect(order.indexOf('ensure') < order.indexOf('nav'), isTrue); // urutan benar
  });
}
