import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/daily_steps.dart';

class WeeklyStepsPoles extends StatelessWidget {
  const WeeklyStepsPoles({super.key, required this.items});

  final List<DailySteps> items;

  @override
  Widget build(BuildContext context) {
    final maxSteps = items.fold<int>(
      1,
      (max, item) => item.steps > max ? item.steps : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Walk Poles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Daily steps for the last 7 days',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 126,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: items
                    .map((item) => _Pole(item: item, maxSteps: maxSteps))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pole extends StatelessWidget {
  const _Pole({required this.item, required this.maxSteps});

  final DailySteps item;
  final int maxSteps;

  @override
  Widget build(BuildContext context) {
    final normalizedHeight = maxSteps == 0
        ? 0.08
        : (item.steps / maxSteps).clamp(0.08, 1.0);
    final targetHeight = 22.0 + (78.0 * normalizedHeight);
    final poleColor = item.isToday ? AppTheme.primary : AppTheme.accent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _compact(item.steps),
          style: TextStyle(
            fontSize: 10,
            color: item.isToday ? Colors.white : AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 22, end: targetHeight),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, animatedHeight, _) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 18,
              height: animatedHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [poleColor, poleColor.withValues(alpha: 0.28)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: poleColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: 11,
            fontWeight: item.isToday ? FontWeight.w700 : FontWeight.w500,
            color: item.isToday ? Colors.white : AppTheme.textMuted,
          ),
          child: Text(item.dayLabel),
        ),
      ],
    );
  }

  String _compact(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }
}
