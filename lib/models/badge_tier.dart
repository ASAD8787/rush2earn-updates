import 'package:flutter/material.dart';

class BadgeTier {
  const BadgeTier({
    required this.name,
    required this.minSteps,
    required this.color,
    required this.glowColor,
  });

  final String name;
  final int minSteps;
  final Color color;
  final Color glowColor;

  static const BadgeTier bronze = BadgeTier(
    name: 'Bronze',
    minSteps: 5000,
    color: Color(0xFFCD7F32),
    glowColor: Color(0xFFB87333),
  );

  static const BadgeTier silver = BadgeTier(
    name: 'Silver',
    minSteps: 10000,
    color: Color(0xFFC0C0C0),
    glowColor: Color(0xFFD7D7D7),
  );

  static const BadgeTier gold = BadgeTier(
    name: 'Gold',
    minSteps: 20000,
    color: Color(0xFFFFD700),
    glowColor: Color(0xFFFFE066),
  );

  static const BadgeTier diamond = BadgeTier(
    name: 'Diamond',
    minSteps: 50000,
    color: Color(0xFF7FD8FF),
    glowColor: Color(0xFFBEEBFF),
  );

  static const List<BadgeTier> tiers = [bronze, silver, gold, diamond];

  static BadgeTier fromSteps(int totalSteps) {
    BadgeTier current = bronze;
    for (final tier in tiers) {
      if (totalSteps >= tier.minSteps) {
        current = tier;
      }
    }
    return current;
  }

  static BadgeTier? nextTier(int totalSteps) {
    for (final tier in tiers) {
      if (totalSteps < tier.minSteps) {
        return tier;
      }
    }
    return null;
  }
}
