import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/nebula_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.onSignedIn,
  });

  final AuthService authService;
  final ValueChanged<AuthUser> onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _error = null;
    });
    try {
      final user = await widget.authService.signInWithGoogle();
      if (!mounted) {
        return;
      }
      widget.onSignedIn(user);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [AppTheme.accent, AppTheme.primary],
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_walk_rounded,
                          color: Color(0xFF061A12),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'rush2earn',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                          icon: _isSigningIn
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            _isSigningIn
                                ? 'Signing in...'
                                : 'Continue With Google',
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
