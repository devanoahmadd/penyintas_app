import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum WeatherState { clear, cloudy, overcast, storm, overwhelmed }

WeatherState weatherStateFrom(int fixedPct) {
  if (fixedPct < 25) return WeatherState.clear;
  if (fixedPct < 50) return WeatherState.cloudy;
  if (fixedPct < 75) return WeatherState.overcast;
  if (fixedPct < 100) return WeatherState.storm;
  return WeatherState.overwhelmed;
}
