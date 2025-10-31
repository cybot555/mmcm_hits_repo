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
  Timer? _pollTimer;
  bool _isVerified = false;

  bool get emailSent => _emailSent;
  bool get canResend => _canResend;
  bool get isSending => _isSending;
  bool get isVerified => _isVerified;

  User? get currentUser => _authRepository.currentUser;

  Future<void> sendVerificationEmail({bool forceResend = false}) async {
    if (_isSending) return;
    if (!forceResend && _emailSent) return;

    _isSending = true;
    notifyListeners();

    try {
      await _authRepository.sendVerificationEmail();
      _emailSent = true;
      _isSending = false;
      notifyListeners();
      _startPolling();
    } catch (e) {
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
      _stopPolling();
      _isVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final verified = await checkIfVerified();
      if (verified) {
        _stopPolling();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  Future<void> signOut() => _authRepository.signOut();
}
