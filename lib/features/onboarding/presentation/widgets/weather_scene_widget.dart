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

                  // Layer 4: Bamboo (3 batang)
                  if (fullDetail || h >= 70)
                    Positioned(
                      bottom: h * 0.2, // duduk di atas near hill
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // L — terbesar, kiri
                          Opacity(
                            opacity: bamOp.clamp(0.0, 1.0),
                            child: _WeatherBamboo(
                              stemHeight: (h * 0.6).clamp(30, 80),
                              color: AppColors.primary,
                              swayAngle: math.sin(
                                    _swayCtrl.value * 2 * math.pi,
                                  ) *
                                  swayAmp,
                            ),
                          ),
                          // M — tengah
                          Opacity(
                            opacity: bamOp.clamp(0.0, 1.0),
                            child: _WeatherBamboo(
                              stemHeight: (h * 0.48).clamp(24, 64),
                              color: AppColors.primary,
                              swayAngle: math.sin(
                                    _swayCtrl.value * 2 * math.pi + 2.094,
                                  ) *
                                  swayAmp,
                            ),
                          ),
                          // S — terkecil, kanan
                          Opacity(
                            opacity: (bamOp * 0.75).clamp(0.0, 1.0),
                            child: _WeatherBamboo(
                              stemHeight: (h * 0.36).clamp(18, 48),
                              color: AppColors.primary,
                              swayAngle: math.sin(
                                    _swayCtrl.value * 2 * math.pi + 4.189,
                                  ) *
                                  swayAmp,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Layer 5: Matahari (kanan atas, hanya clear + cloudy)
                  if (fullDetail && sunOp > 0.01)
                    Positioned(
                      top: h * 0.1,
                      right: w * 0.1,
                      child: Opacity(
                        opacity: sunOp.clamp(0.0, 1.0),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                      ),
                    ),

                  // Layer 6: Awan (cloudy, overcast, storm)
                  if (fullDetail && cloudOp > 0.01) ...[
                    // Awan 1 — kiri atas
                    Positioned(
                      top: h * 0.08,
                      left: w * 0.05 + ambient * 6,
                      child: Opacity(
                        opacity: cloudOp.clamp(0.0, 1.0),
                        child: _CloudShape(
                          color: Color.lerp(
                            const Color(0xFFF0F8FC), // clear/cloudy: putih
                            const Color(0xFFA0ACB4), // storm: abu gelap
                            (_lerp(
                                  _kScene[_fromState]!.rainOpacity,
                                  _kScene[_toState]!.rainOpacity,
                                  t,
                                ) *
                                1.5)
                                .clamp(0.0, 1.0),
                          )!,
                          width: w * 0.38,
                        ),
                      ),
                    ),
                    // Awan 2 — kanan atas, sedikit lebih kecil
                    if (_lerp(
                          _kScene[_fromState]!.cloudOpacity,
                          _kScene[_toState]!.cloudOpacity,
                          t,
                        ) >
                        0.4)
                      Positioned(
                        top: h * 0.04,
                        right: w * 0.08 - ambient * 5,
                        child: Opacity(
                          opacity:
                              (cloudOp * 0.85).clamp(0.0, 1.0),
                          child: _CloudShape(
                            color: Color.lerp(
                              const Color(0xFFE4F0F4),
                              const Color(0xFF8C9AA0),
                              (_lerp(
                                    _kScene[_fromState]!.rainOpacity,
                                    _kScene[_toState]!.rainOpacity,
                                    t,
                                  ) *
                                  1.5)
                                  .clamp(0.0, 1.0),
                            )!,
                            width: w * 0.28,
                          ),
                        ),
                      ),
                  ],

                  // Layer 7: Hujan (storm only)
                  if (rainOp > 0.01)
                    Positioned.fill(
                      child: Opacity(
                        opacity: rainOp.clamp(0.0, 1.0),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: List.generate(7, (i) {
                            final xFrac = const [
                              0.08, 0.20, 0.34, 0.48, 0.62, 0.76, 0.89
                            ][i];
                            final fallPhase =
                                (_ambientCtrl.value + i / 7) % 1.0;
                            return Positioned(
                              left: w * xFrac,
                              top: h * fallPhase - 14,
                              child: Transform.rotate(
                                angle: 0.22, // ~13° miring
                                child: Container(
                                  width: 1.5,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA0C8E0)
                                        .withAlpha(180),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                  // Layer 8: Kabut (overwhelmed only)
                  if (fogOp > 0.01)
                    Positioned.fill(
                      child: Opacity(
                        opacity:
                            (fogOp * (0.7 + 0.2 * ambient)).clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE8F2E8),
                                Color(0xFFD4E8D4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _WeatherBamboo extends StatelessWidget {
  const _WeatherBamboo({
    required this.stemHeight,
    required this.color,
    required this.swayAngle, // radians, pivot di bawah
  });

  final double stemHeight;
  final Color color;
  final double swayAngle;

  @override
  Widget build(BuildContext context) {
    final stemW = (stemHeight * 0.09).clamp(4.0, 10.0);
    final nodeH = stemW * 0.55;

    return Transform.rotate(
      angle: swayAngle,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: stemW * 4,
        height: stemHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Stem
            Positioned(
              bottom: 0,
              left: stemW * 1.5,
              child: Container(
                width: stemW,
                height: stemHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(stemW / 2),
                ),
              ),
            ),
            // Node bawah
            Positioned(
              bottom: stemHeight * 0.3,
              left: stemW * 0.9,
              child: Container(
                width: stemW * 2.2,
                height: nodeH,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Node atas
            Positioned(
              bottom: stemHeight * 0.58,
              left: stemW * 0.9,
              child: Container(
                width: stemW * 2.2,
                height: nodeH,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Daun kanan
            Positioned(
              bottom: stemHeight * 0.68,
              left: stemW * 2.3,
              child: Transform.rotate(
                angle: -0.42,
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: stemHeight * 0.24,
                  height: stemW * 0.85,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            // Daun kiri
            Positioned(
              bottom: stemHeight * 0.52,
              left: stemW * -0.1,
              child: Transform.rotate(
                angle: 0.42,
                alignment: Alignment.bottomRight,
                child: Container(
                  width: stemHeight * 0.2,
                  height: stemW * 0.85,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudShape extends StatelessWidget {
  const _CloudShape({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final baseH = width * 0.3;
    return SizedBox(
      width: width,
      height: baseH + width * 0.28,
      child: Stack(
        children: [
          // Base pill
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: baseH,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          // Tonjolan kiri
          Positioned(
            bottom: baseH * 0.35,
            left: width * 0.08,
            child: Container(
              width: width * 0.4,
              height: width * 0.4,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          // Tonjolan tengah
          Positioned(
            bottom: baseH * 0.3,
            left: width * 0.35,
            child: Container(
              width: width * 0.3,
              height: width * 0.3,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
