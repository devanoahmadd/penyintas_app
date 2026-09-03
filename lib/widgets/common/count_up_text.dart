import 'package:flutter/material.dart';

/// Menganimasikan angka dari nilai sebelumnya ke nilai baru.
/// Durasi 420 ms, easeOutCubic. Format lewat callback [format].
///
/// Dipromosikan dari `OnboardingCountUp` (milik fitur onboarding) supaya bisa
/// dipakai lintas-fitur — halaman Konsistensi memerlukannya untuk angka streak.
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    required this.format,
  });

  final int value;
  final TextStyle style;
  final String Function(int) format;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late int _from;
  late int _to;
  late int _displayed;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _to = widget.value;
    _displayed = widget.value;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(_onTick);
  }

  @override
  void didUpdateWidget(CountUpText old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _displayed;
      _to = widget.value;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTick() {
    // easeOutCubic: 1 - (1-t)^3
    final t = _ctrl.value;
    final ease = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
    setState(() {
      _displayed = (_from + (_to - _from) * ease).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget.format(_displayed), style: widget.style);
  }
}
