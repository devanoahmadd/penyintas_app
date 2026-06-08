import 'dart:math' as math;

import 'package:flutter/material.dart';

// ignore: unused_import — used in Tasks 3–6 (dark mode, bamboo, sun layers)
import '../../../../core/theme/app_colors.dart';

enum WeatherState { clear, cloudy, overcast, storm, overwhelmed }

WeatherState weatherStateFrom(int fixedPct) {
  if (fixedPct < 25) return WeatherState.clear;
  if (fixedPct < 50) return WeatherState.cloudy;
  if (fixedPct < 75) return WeatherState.overcast;
  if (fixedPct < 100) return WeatherState.storm;
  return WeatherState.overwhelmed;
}

class _SceneValues {
  const _SceneValues({
    required this.skyTop,
    required this.skyBot,
    required this.hillFar,
    required this.hillNear,
    required this.sunOpacity,
    required this.cloudOpacity,
    required this.rainOpacity,
    required this.fogOpacity,
    required this.bamOpacity,
    required this.swayAmp, // radians
    required this.swayMs,
  });

  final Color skyTop, skyBot, hillFar, hillNear;
  final double sunOpacity, cloudOpacity, rainOpacity, fogOpacity, bamOpacity;
  final double swayAmp;
  final int swayMs;
}

const _kScene = <WeatherState, _SceneValues>{
  WeatherState.clear: _SceneValues(
    skyTop: Color(0xFF8DD4F0), skyBot: Color(0xFFC8EEF8),
    hillFar: Color(0xFF7EC87A), hillNear: Color(0xFF5AB05A),
    sunOpacity: 1.0, cloudOpacity: 0.0, rainOpacity: 0.0,
    fogOpacity: 0.0, bamOpacity: 1.0,
    swayAmp: 0.035, swayMs: 3000,
  ),
  WeatherState.cloudy: _SceneValues(
    skyTop: Color(0xFF7AAECC), skyBot: Color(0xFFB8D4E0),
    hillFar: Color(0xFF5E9E6A), hillNear: Color(0xFF4A8A55),
    sunOpacity: 0.5, cloudOpacity: 0.9, rainOpacity: 0.0,
    fogOpacity: 0.0, bamOpacity: 0.85,
    swayAmp: 0.052, swayMs: 2500,
  ),
  WeatherState.overcast: _SceneValues(
    skyTop: Color(0xFF4A6878), skyBot: Color(0xFF788C98),
    hillFar: Color(0xFF344E38), hillNear: Color(0xFF263A28),
    sunOpacity: 0.0, cloudOpacity: 1.0, rainOpacity: 0.0,
    fogOpacity: 0.0, bamOpacity: 0.65,
    swayAmp: 0.087, swayMs: 1800,
  ),
  WeatherState.storm: _SceneValues(
    skyTop: Color(0xFF2A3C48), skyBot: Color(0xFF445A68),
    hillFar: Color(0xFF1E3028), hillNear: Color(0xFF162218),
    sunOpacity: 0.0, cloudOpacity: 1.0, rainOpacity: 0.9,
    fogOpacity: 0.0, bamOpacity: 0.45,
    swayAmp: 0.157, swayMs: 800,
  ),
  WeatherState.overwhelmed: _SceneValues(
    skyTop: Color(0xFFC8D8C8), skyBot: Color(0xFFD8E8D8),
    hillFar: Color(0xFF506C50), hillNear: Color(0xFF3C5C3C),
    sunOpacity: 0.0, cloudOpacity: 0.0, rainOpacity: 0.0,
    fogOpacity: 0.85, bamOpacity: 0.25,
    swayAmp: 0.0, swayMs: 3000,
  ),
};

class WeatherSceneWidget extends StatefulWidget {
  const WeatherSceneWidget({
    super.key,
    required this.state,
    required this.isDark,
  });

  final WeatherState state;
  final bool isDark;

  @override
  State<WeatherSceneWidget> createState() => _WeatherSceneState();
}

class _WeatherSceneState extends State<WeatherSceneWidget>
    with TickerProviderStateMixin {
  late AnimationController _transitionCtrl; // state-to-state lerp, 600ms
  late AnimationController _swayCtrl;       // bambu goyang, periode bervariasi
  late AnimationController _ambientCtrl;    // cloud drift + rain + fog, 4000ms

  WeatherState _fromState = WeatherState.clear;
  WeatherState _toState = WeatherState.clear;

  @override
  void initState() {
    super.initState();
    _fromState = widget.state;
    _toState = widget.state;

    _transitionCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..value = 1.0;

    final vals = _kScene[widget.state]!;
    _swayCtrl = AnimationController(
      duration: Duration(milliseconds: vals.swayMs),
      vsync: this,
    );
    if (vals.swayAmp > 0) _swayCtrl.repeat();

    _ambientCtrl = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();
  }

  @override
  void didUpdateWidget(WeatherSceneWidget old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _fromState = old.state;
      _toState = widget.state;
      _transitionCtrl.forward(from: 0);
      _updateSwaySpeed(widget.state);
    }
  }

  void _updateSwaySpeed(WeatherState state) {
    final vals = _kScene[state]!;
    if (vals.swayAmp == 0.0) {
      _swayCtrl.stop();
    } else {
      _swayCtrl.duration = Duration(milliseconds: vals.swayMs);
      _swayCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _transitionCtrl.dispose();
    _swayCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_transitionCtrl, _swayCtrl, _ambientCtrl]),
      builder: (context, _) {
        final from = _kScene[_fromState]!;
        final to = _kScene[_toState]!;
        final t = Curves.easeInOut.transform(_transitionCtrl.value);

        final skyTop = Color.lerp(from.skyTop, to.skyTop, t)!;
        final skyBot = Color.lerp(from.skyBot, to.skyBot, t)!;
        final hillFar = Color.lerp(from.hillFar, to.hillFar, t)!;
        final hillNear = Color.lerp(from.hillNear, to.hillNear, t)!;
        final sunOp = _lerp(from.sunOpacity, to.sunOpacity, t);
        final cloudOp = _lerp(from.cloudOpacity, to.cloudOpacity, t);
        final rainOp = _lerp(from.rainOpacity, to.rainOpacity, t);
        final fogOp = _lerp(from.fogOpacity, to.fogOpacity, t);
        final bamOp = _lerp(from.bamOpacity, to.bamOpacity, t);
        final swayAmp = _lerp(from.swayAmp, to.swayAmp, t);

        // Ambient oscillation value (-1 → +1 sinusoidal)
        final ambient = math.sin(_ambientCtrl.value * 2 * math.pi);

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight < 60) return const SizedBox.shrink();

            final fullDetail = constraints.maxHeight >= 100;
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Layer 1: Sky gradient (always shown)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [skyTop, skyBot],
                        ),
                      ),
                    ),
                  ),

                  // Layer 2: Far hill
                  Positioned(
                    bottom: h * 0.22,
                    left: -w * 0.08,
                    right: -w * 0.08,
                    child: Container(
                      height: h * 0.45,
                      decoration: BoxDecoration(
                        color: hillFar,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(999),
                        ),
                      ),
                    ),
                  ),

                  // Layer 3: Near hill
                  Positioned(
                    bottom: 0,
                    left: -w * 0.05,
                    right: -w * 0.05,
                    child: Container(
                      height: h * 0.3,
                      decoration: BoxDecoration(
                        color: hillNear,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(999),
                        ),
                      ),
                    ),
                  ),

                  // Layers 4-8 added in later tasks (sun, clouds, bamboo, rain, fog)
                ],
              ),
            );
          },
        );
      },
    );
  }
}
