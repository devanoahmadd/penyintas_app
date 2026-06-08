import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Widget _pump(WeatherState state) => MaterialApp(
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
        await tester.pumpWidget(_pump(state));
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('ClipRRect ada di tree', (tester) async {
      await tester.pumpWidget(_pump(WeatherState.clear));
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
}
