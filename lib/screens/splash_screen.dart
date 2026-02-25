import 'package:flutter/material.dart';
import 'dart:async';

import '../widgets/nebula_background.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _startupTimer;

  @override
  void initState() {
    super.initState();
    _startupTimer = Timer(const Duration(milliseconds: 1600), _bootstrap);
  }

  Future<void> _bootstrap() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(userDisplayName: 'Guest'),
      ),
    );
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NebulaBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2DE2E6), Color(0xFF00FFA8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2DE2E6).withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: Color(0xFF04151F),
                  size: 52,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'rush2earn',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Walk. Sync. Earn.',
                style: TextStyle(color: Colors.white70, letterSpacing: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
