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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>['email', 'profile'],
  );

  Future<AuthUser?> tryRestoreSession() async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) {
      return null;
    }
    return _toUser(account);
  }

  Future<AuthUser> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw const AuthException('Google sign-in was canceled.');
    }
    return _toUser(account);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  AuthUser _toUser(GoogleSignInAccount account) {
    return AuthUser(
      displayName: account.displayName ?? 'Rush2Earn User',
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
