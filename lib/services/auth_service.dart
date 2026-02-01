import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth.
/// Exposes only what the app needs: the current user stream, sign-in,
/// sign-out, and account deletion.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Emits the current user whenever auth state changes (sign-in, sign-out,
  /// token refresh). UI layers listen to this stream to react reactively.
  Stream<User?> get userStream => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  /// Signs the user in with email + password.
  /// Throws [FirebaseAuthException] on failure — callers handle the error.
  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Creates a new account then signs in automatically.
  Future<UserCredential> createAccount(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  /// Signs in without an account for first-time users who haven't registered yet.
  /// Anonymous users can be upgraded to a real account later via [linkWithEmail].
  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  /// Upgrades an anonymous user to a permanent email/password account.
  /// All their data (Firestore documents with their uid) is preserved.
  Future<UserCredential> linkWithEmail(String email, String password) {
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    return _auth.currentUser!.linkWithCredential(credential);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() => _auth.signOut();

  /// Deletes the account. Requires recent authentication — callers should
  /// re-authenticate before calling this if the last sign-in was > 5 minutes ago.
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}
