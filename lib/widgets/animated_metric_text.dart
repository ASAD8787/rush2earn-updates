import 'package:flutter/material.dart';

class AnimatedMetricText extends StatelessWidget {
  const AnimatedMetricText({
    super.key,
    required this.value,
    this.decimals = 0,
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 420),
  });

  final double value;
  final int decimals;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final formatted = animatedValue.toStringAsFixed(decimals);
        return Text('$formatted$suffix', style: style);
      },
    );
  }
}
