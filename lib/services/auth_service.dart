import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  const AuthUser({
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  final String displayName;
  final String email;
  final String? photoUrl;
}

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _googleSignIn.initialize();
    _initialized = true;
  }

  Future<AuthUser?> tryRestoreSession() async {
    await _ensureInitialized();
    final restoreFuture = _googleSignIn.attemptLightweightAuthentication();
    final account = restoreFuture == null ? null : await restoreFuture;
    if (account == null) {
      return null;
    }
    return _toUser(account);
  }

  Future<AuthUser> signInWithGoogle() async {
    await _ensureInitialized();
    try {
      final account = await _googleSignIn.authenticate();
      return _toUser(account);
    } on GoogleSignInException catch (e) {
      throw AuthException(_friendlyError(e));
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }

  AuthUser _toUser(GoogleSignInAccount account) {
    return AuthUser(
      displayName: account.displayName ?? 'Rush2Earn User',
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }

  String _friendlyError(GoogleSignInException exception) {
    switch (exception.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google sign-in was canceled.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in UI unavailable on this device.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Signed-in account does not match current session.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google Sign-In is not configured correctly for this build.';
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
