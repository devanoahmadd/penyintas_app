import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/theme/app_weather_palette.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/weather_scene_widget.dart';

void main() {
  group('weatherStateFrom', () {
    test('0% → clear', () => expect(weatherStateFrom(0), WeatherState.clear));
    test('24% → clear', () => expect(weatherStateFrom(24), WeatherState.clear));
    test(
      '25% → cloudy',
      () => expect(weatherStateFrom(25), WeatherState.cloudy),
    );
    test(
      '49% → cloudy',
      () => expect(weatherStateFrom(49), WeatherState.cloudy),
    );
    test(
      '50% → overcast',
      () => expect(weatherStateFrom(50), WeatherState.overcast),
    );
    test(
      '74% → overcast',
      () => expect(weatherStateFrom(74), WeatherState.overcast),
    );
    test('75% → storm', () => expect(weatherStateFrom(75), WeatherState.storm));
    test('99% → storm', () => expect(weatherStateFrom(99), WeatherState.storm));
    test(
      '100% → overwhelmed',
      () => expect(weatherStateFrom(100), WeatherState.overwhelmed),
    );
    test(
      '150% → overwhelmed',
      () => expect(weatherStateFrom(150), WeatherState.overwhelmed),
    );
  });

  Widget pump(WeatherState state) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 200,
        child: WeatherSceneWidget(state: state, isDark: false),
      ),
    ),
  );

  group('WeatherSceneWidget smoke', () {
    for (final state in WeatherState.values) {
      testWidgets('renders state $state tanpa throw', (tester) async {
        await tester.pumpWidget(pump(state));
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('ClipRRect ada di tree', (tester) async {
      await tester.pumpWidget(pump(WeatherState.clear));
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('height < 60dp → SizedBox.shrink (tidak ada ClipRRect)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 40,
              child: WeatherSceneWidget(
                state: WeatherState.clear,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ClipRRect), findsNothing);
    });
  });

  group('WeatherSceneWidget state transitions', () {
    testWidgets('state change clear → storm tidak throw', (tester) async {
      late StateSetter outerSetState;
      WeatherState current = WeatherState.clear;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            outerSetState = setState;
            return MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 200,
                  child: WeatherSceneWidget(state: current, isDark: false),
                ),
              ),
            );
          },
        ),
      );

      // Trigger state change
      outerSetState(() => current = WeatherState.storm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
    });

    testWidgets('state change storm → overwhelmed tidak throw', (tester) async {
      late StateSetter outerSetState;
      WeatherState current = WeatherState.storm;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            outerSetState = setState;
            return MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 200,
                  child: WeatherSceneWidget(state: current, isDark: false),
                ),
              ),
            );
          },
        ),
      );

      outerSetState(() => current = WeatherState.overwhelmed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
    });
  });

  group('WeatherSceneWidget edge cases', () {
    testWidgets('height tepat 60dp menampilkan ClipRRect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 60,
              child: WeatherSceneWidget(
                state: WeatherState.clear,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('tidak ada overflow pada semua states di height 80dp', (
      tester,
    ) async {
      for (final state in WeatherState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 80,
                child: WeatherSceneWidget(state: state, isDark: false),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.takeException(),
          isNull,
          reason: 'State $state: tidak boleh ada exception',
        );
      }
    });
  });

  group('AppWeatherPalette', () {
    test('semua token palette tersedia dan non-null', () {
      expect(AppWeatherPalette.skyTopClear, isNotNull);
      expect(AppWeatherPalette.hillBackClearDark, isNotNull);
      expect(AppWeatherPalette.moonColor, isNotNull);
      expect(AppWeatherPalette.cloudNightBase, isNotNull);
      expect(AppWeatherPalette.rainNightColor, isNotNull);
      expect(AppWeatherPalette.fogNightStart, isNotNull);
    });
  });

  group('WeatherSceneWidget dark mode smoke', () {
    Widget pumpDark(WeatherState state) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 200,
          child: WeatherSceneWidget(state: state, isDark: true),
        ),
      ),
    );

    for (final state in WeatherState.values) {
      testWidgets('dark mode state $state renders tanpa throw', (tester) async {
        await tester.pumpWidget(pumpDark(state));
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('WeatherSceneWidget stars', () {
    Widget pumpDark(WeatherState state) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 200,
          child: WeatherSceneWidget(state: state, isDark: true),
        ),
      ),
    );

    // Stars = Container white circle (BoxShape.circle + Colors.white)
    // Safe: cloud blobs use BorderRadius.circular(999) NOT BoxShape.circle
    // Sun = Color(0xFFFFD54F), Moon inner = AppWeatherPalette.moonColor — no collision
    Finder starFinder() => find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          (widget.decoration as BoxDecoration).color == Colors.white,
    );

    testWidgets('dark clear: bintang ter-render', (tester) async {
      await tester.pumpWidget(pumpDark(WeatherState.clear));
      await tester.pump(const Duration(milliseconds: 100));
      expect(starFinder(), findsWidgets);
    });

    testWidgets('dark cloudy: bintang ter-render (lebih sedikit dari clear)', (
      tester,
    ) async {
      await tester.pumpWidget(pumpDark(WeatherState.cloudy));
      await tester.pump(const Duration(milliseconds: 100));
      expect(starFinder(), findsWidgets);
    });

    testWidgets('dark overcast: tidak ada bintang', (tester) async {
      await tester.pumpWidget(pumpDark(WeatherState.overcast));
      await tester.pump(const Duration(milliseconds: 100));
      expect(starFinder(), findsNothing);
    });

    testWidgets('dark storm: tidak ada bintang', (tester) async {
      await tester.pumpWidget(pumpDark(WeatherState.storm));
      await tester.pump(const Duration(milliseconds: 100));
      expect(starFinder(), findsNothing);
    });

    testWidgets('light mode clear: tidak ada bintang', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: WeatherSceneWidget(
                state: WeatherState.clear,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(starFinder(), findsNothing);
    });
  });

  group('WeatherSceneWidget sun/moon', () {
    Widget pumpScene({required WeatherState state, required bool isDark}) =>
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: WeatherSceneWidget(state: state, isDark: isDark),
            ),
          ),
        );

    testWidgets('light mode clear: matahari kuning ada', (tester) async {
      await tester.pumpWidget(
        pumpScene(state: WeatherState.clear, isDark: false),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  const Color(0xFFFFD54F),
        ),
        findsOneWidget,
      );
    });

    testWidgets('dark mode clear: matahari kuning TIDAK ada', (tester) async {
      await tester.pumpWidget(
        pumpScene(state: WeatherState.clear, isDark: true),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  const Color(0xFFFFD54F),
        ),
        findsNothing,
      );
    });

    testWidgets('dark mode clear: moon color ada', (tester) async {
      await tester.pumpWidget(
        pumpScene(state: WeatherState.clear, isDark: true),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  AppWeatherPalette.moonColor,
        ),
        findsOneWidget,
      );
    });

    testWidgets('dark mode overcast: tidak ada sun maupun moon', (
      tester,
    ) async {
      await tester.pumpWidget(
        pumpScene(state: WeatherState.overcast, isDark: true),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              ((widget.decoration as BoxDecoration).color ==
                      const Color(0xFFFFD54F) ||
                  (widget.decoration as BoxDecoration).color ==
                      AppWeatherPalette.moonColor),
        ),
        findsNothing,
      );
    });
  });

  group('WeatherSceneWidget night palette — cloud/rain/fog', () {
    Widget pumpDark(WeatherState state) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 200,
          child: WeatherSceneWidget(state: state, isDark: true),
        ),
      ),
    );

    testWidgets('dark cloudy: awan tidak berwarna putih siang (#F0F8FC)', (
      tester,
    ) async {
      await tester.pumpWidget(pumpDark(WeatherState.cloudy));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  const Color(0xFFF0F8FC),
        ),
        findsNothing,
      );
    });

    testWidgets('dark storm: hujan tidak berwarna biru muda siang (#A0C8E0)', (
      tester,
    ) async {
      await tester.pumpWidget(pumpDark(WeatherState.storm));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  const Color(0xFFA0C8E0).withAlpha(180),
        ),
        findsNothing,
      );
    });

    testWidgets('dark overwhelmed: kabut tidak pakai warna hijau cerah siang', (
      tester,
    ) async {
      await tester.pumpWidget(pumpDark(WeatherState.overwhelmed));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final deco = widget.decoration;
          if (deco is! BoxDecoration) return false;
          final gradient = deco.gradient;
          if (gradient is! LinearGradient) return false;
          return gradient.colors.contains(const Color(0xFFE8F2E8));
        }),
        findsNothing,
      );
    });
  });
}
