import 'package:firebase_auth/firebase_auth.dart';

/// Provides an abstraction layer over [FirebaseAuth] so that view models
/// interact with a simple, testable API.
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(FirebaseAuth auth) : _auth = auth;

  Stream<User?> watchUser() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _auth.currentUser;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> signOut() => _auth.signOut();
}
