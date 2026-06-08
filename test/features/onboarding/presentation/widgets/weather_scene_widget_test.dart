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
}
