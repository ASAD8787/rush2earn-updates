import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.active,
    this.activeLabel,
    this.inactiveLabel,
  });

  final String label;
  final bool active;
  final String? activeLabel;
  final String? inactiveLabel;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? AppTheme.primary.withValues(alpha: 0.16)
        : Colors.white10;
    final border = active
        ? AppTheme.primary.withValues(alpha: 0.45)
        : Colors.white24;
    final dot = active ? AppTheme.primary : AppTheme.textMuted;
    final value = active
        ? (activeLabel ?? 'Active')
        : (inactiveLabel ?? 'Inactive');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
