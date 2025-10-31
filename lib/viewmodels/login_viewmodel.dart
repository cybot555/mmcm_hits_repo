import 'package:firebase_auth/firebase_auth.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      setError('Email and password are required.');
      return false;
    }

    setLoading(true);
    resetError();

    try {
      await _authRepository.signIn(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      setError(_readableError(e));
      return false;
    } catch (e) {
      setError('Could not sign in. Please try again.');
      return false;
    } finally {
      setLoading(false);
    }
  }

  String _readableError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return exception.message ?? 'Authentication failed.';
    }
  }
}
