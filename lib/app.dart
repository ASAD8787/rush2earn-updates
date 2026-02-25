import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth_gate_screen.dart';

class Rush2EarnApp extends StatelessWidget {
  const Rush2EarnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rush2earn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthGateScreen(),
    );
  }
}
