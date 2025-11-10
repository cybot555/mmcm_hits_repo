import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class EmailVerificationViewModel extends BaseViewModel {
  EmailVerificationViewModel(this._authRepository);

  final AuthRepository _authRepository;

  bool _emailSent = false;
  bool _canResend = true;
  bool _isSending = false;
  bool _isVerified = false;
  bool _requestedInitialEmail = false;

  bool get emailSent => _emailSent;
  bool get canResend => _canResend;
  bool get isSending => _isSending;
  bool get isVerified => _isVerified;

  User? get currentUser => _authRepository.currentUser;

  Future<void> ensureInitialEmailSent() async {
    if (_requestedInitialEmail) return;
    _requestedInitialEmail = true;
    await sendVerificationEmail();
  }

  Future<void> sendVerificationEmail({bool forceResend = false}) async {
    if (_isSending) return;
    if (!forceResend && _emailSent) return;

    _isSending = true;
    notifyListeners();

    if (_authRepository.currentUser == null) {
      if (!forceResend) {
        _requestedInitialEmail = false;
      }
      _isSending = false;
      setError('Please sign in again to request a verification email.');
      notifyListeners();
      return;
    }

    try {
      await _authRepository.sendVerificationEmail();
      _emailSent = true;
      _isSending = false;
      notifyListeners();
    } catch (e) {
      if (!forceResend) {
        _requestedInitialEmail = false;
      }
      _isSending = false;
      setError('Failed to send verification email.');
      notifyListeners();
    }
  }

  Future<void> resendVerificationEmail() async {
    if (!_canResend || _isSending) return;

    _canResend = false;
    notifyListeners();

    await sendVerificationEmail(forceResend: true);
    await Future<void>.delayed(const Duration(seconds: 30));
    _canResend = true;
    notifyListeners();
  }

  Future<bool> checkIfVerified() async {
    final refreshed = await _authRepository.refreshCurrentUser();
    if (refreshed?.emailVerified ?? false) {
      _isVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> signOut() => _authRepository.signOut();
}
