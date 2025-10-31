import 'package:firebase_auth/firebase_auth.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class AuthViewModel extends BaseViewModel {
  AuthViewModel(this._authRepository);

  final AuthRepository _authRepository;

  String? _lastRefreshedUid;
  DateTime? _lastRefreshedAt;
  bool _isRefreshing = false;

  Stream<User?> get authState => _authRepository.watchUser();

  User? get currentUser => _authRepository.currentUser;

  Future<User?> refreshUser() => _authRepository.refreshCurrentUser();

  Future<void> refreshUserIfNeeded(
    User user, {
    bool force = false,
  }) async {
    if (_isRefreshing) return;

    final now = DateTime.now();
    final shouldRefresh = force ||
        _lastRefreshedUid != user.uid ||
        _lastRefreshedAt == null ||
        now.difference(_lastRefreshedAt!) > const Duration(seconds: 5);

    if (!shouldRefresh) return;

    _isRefreshing = true;
    try {
      await _authRepository.refreshCurrentUser();
      _lastRefreshedUid = user.uid;
      _lastRefreshedAt = DateTime.now();

      if (errorMessage != null) {
        resetError();
      }
    } on FirebaseAuthException catch (e) {
      setError(e.message ?? 'Failed to refresh session.');
    } catch (_) {
      setError('Failed to refresh session.');
    } finally {
      _isRefreshing = false;
    }
  }
}
