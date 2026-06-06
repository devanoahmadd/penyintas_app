import 'package:flutter/material.dart';

/// Animates a number from its previous value to a new value.
/// Duration 420ms, easeOutCubic. Format via [format] callback.
class OnboardingCountUp extends StatefulWidget {
  const OnboardingCountUp({
    super.key,
    required this.value,
    required this.style,
    required this.format,
  });

  final int value;
  final TextStyle style;
  final String Function(int) format;

  @override
  State<OnboardingCountUp> createState() => _OnboardingCountUpState();
}

class _OnboardingCountUpState extends State<OnboardingCountUp>
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
  void didUpdateWidget(OnboardingCountUp old) {
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
