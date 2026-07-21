import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/widgets/common/app_bottom_nav_bar.dart';

GoRouter _router({int currentIndex = 0, VoidCallback? onFabTap}) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: currentIndex,
            onFabTap: onFabTap ?? () {},
          ),
        ),
      ),
      GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/transactions', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/budget', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
    ],
  );
}

Widget _harness({int currentIndex = 0, VoidCallback? onFabTap}) =>
    MaterialApp.router(
      routerConfig: _router(currentIndex: currentIndex, onFabTap: onFabTap),
    );

void main() {
  group('AppBottomNavBar', () {
    testWidgets('renders all 4 tab labels + Catat', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_harness());
      await tester.pump();

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Transaksi'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Saya'), findsOneWidget);
      expect(find.text('Catat'), findsOneWidget);
    });

    testWidgets('tapping FAB fires onFabTap callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tapped = false;
      await tester.pumpWidget(_harness(onFabTap: () => tapped = true));
      await tester.pump();

      final catat = find.text('Catat');
      expect(catat, findsOneWidget);
      final catPos = tester.getCenter(catat);
      await tester.tapAt(Offset(catPos.dx, catPos.dy - 34));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('widget renders without exception in dark mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _router(),
          theme: ThemeData(brightness: Brightness.dark),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
