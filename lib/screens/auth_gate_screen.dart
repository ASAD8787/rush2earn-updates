import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/nebula_background.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthService _authService = AuthService();
  AuthUser? _currentUser;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final user = await _authService.tryRestoreSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = user;
      _isCheckingSession = false;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return Scaffold(
        body: NebulaBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'rush2earn',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return LoginScreen(
        authService: _authService,
        onSignedIn: (user) {
          setState(() {
            _currentUser = user;
          });
        },
      );
    }

    return HomeScreen(
      userDisplayName: _currentUser!.displayName,
      onSignOutPressed: _signOut,
    );
  }
}
