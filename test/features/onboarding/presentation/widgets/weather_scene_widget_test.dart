import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/theme/app_weather_palette.dart';
import 'package:penyintas_app/features/onboarding/presentation/widgets/weather_scene_widget.dart';

void main() {
  group('weatherStateFrom', () {
    test('0% → clear', () => expect(weatherStateFrom(0), WeatherState.clear));
    test('24% → clear', () => expect(weatherStateFrom(24), WeatherState.clear));
    test('25% → cloudy', () => expect(weatherStateFrom(25), WeatherState.cloudy));
    test('49% → cloudy', () => expect(weatherStateFrom(49), WeatherState.cloudy));
    test('50% → overcast', () => expect(weatherStateFrom(50), WeatherState.overcast));
    test('74% → overcast', () => expect(weatherStateFrom(74), WeatherState.overcast));
    test('75% → storm', () => expect(weatherStateFrom(75), WeatherState.storm));
    test('99% → storm', () => expect(weatherStateFrom(99), WeatherState.storm));
    test('100% → overwhelmed', () => expect(weatherStateFrom(100), WeatherState.overwhelmed));
    test('150% → overwhelmed', () => expect(weatherStateFrom(150), WeatherState.overwhelmed));
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

    testWidgets('height < 60dp → SizedBox.shrink (tidak ada ClipRRect)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 40,
              child: WeatherSceneWidget(state: WeatherState.clear, isDark: false),
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

    testWidgets('tidak ada overflow pada semua states di height 80dp', (tester) async {
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
        expect(tester.takeException(), isNull,
            reason: 'State $state: tidak boleh ada exception');
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
}
