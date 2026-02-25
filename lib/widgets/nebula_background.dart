import 'package:flutter/material.dart';

class NebulaBackground extends StatelessWidget {
  const NebulaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF061126),
            Color(0xFF04151F),
            Color(0xFF081733),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _GlowOrb(
              color: const Color(0xFF2DE2E6).withValues(alpha: 0.26),
              size: 240,
            ),
          ),
          Positioned(
            right: -70,
            bottom: 60,
            child: _GlowOrb(
              color: const Color(0xFF00FFA8).withValues(alpha: 0.20),
              size: 220,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
