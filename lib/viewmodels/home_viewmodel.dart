import 'dart:async';

import 'package:mmcm_hits/models/user_model.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel(
    this._authRepository,
    this._userRepository, {
    required String uid,
  }) : _uid = uid;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final String _uid;

  AppUser? _user;
  StreamSubscription<AppUser?>? _subscription;
  int _currentIndex = 0;
  bool _hasLoadedInitialUser = false;

  AppUser? get user => _user;
  String get role => _user?.role ?? '';
  String get uid => _uid;
  int get currentIndex => _currentIndex;
  bool get hasLoadedInitialUser => _hasLoadedInitialUser;

  void initialise() {
    _subscription ??=
        _userRepository.watchUser(_uid).listen((appUser) {
          _hasLoadedInitialUser = true;
          _user = appUser;

          if (appUser == null) {
            setError('We could not find your profile information.');
            return;
          }

          if (errorMessage != null) {
            resetError();
          } else {
            notifyListeners();
          }
        }, onError: (error) {
          _hasLoadedInitialUser = true;
          setError('Failed to load user profile.');
        });
  }

  void changeTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> logout() => _authRepository.signOut();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
