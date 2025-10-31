import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mmcm_hits/models/user_model.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/storage_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class SignupViewModel extends BaseViewModel {
  SignupViewModel({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    required StorageRepository storageRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       _storageRepository = storageRepository;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final StorageRepository _storageRepository;

  String? _selectedCollege;
  String? _selectedProgram;
  String? _selectedRole;
  File? _licenseFile;
  File? _orcrFile;

  String? get selectedCollege => _selectedCollege;
  String? get selectedProgram => _selectedProgram;
  String? get selectedRole => _selectedRole;
  bool get isDriver => _selectedRole == 'Driver';

  bool get driverDocsReady => _licenseFile != null && _orcrFile != null;

  void updateCollegeAndProgram(String? college, String? program) {
    _selectedCollege = college;
    _selectedProgram = program;
    notifyListeners();
  }

  void updateRole(String? role) {
    _selectedRole = role;
    notifyListeners();
  }

  void updateDriverDocuments({File? license, File? orcr}) {
    _licenseFile = license;
    _orcrFile = orcr;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    setLoading(true);
    resetError();

    try {
      final trimmedEmail = email.trim().toLowerCase();
      if (!trimmedEmail.endsWith('@mcm.edu.ph')) {
        setError('Please use your school email (@mcm.edu.ph).');
        return false;
      }

      if (password != confirmPassword) {
        setError('Passwords do not match.');
        return false;
      }

      if (_selectedRole == null) {
        setError('Select Driver or Hitcher.');
        return false;
      }

      if (isDriver && !driverDocsReady) {
        setError('Upload Driver’s License and OR/CR.');
        return false;
      }

      final credential = await _authRepository.register(
        email: trimmedEmail,
        password: password.trim(),
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        setError('Failed to create account.');
        return false;
      }

      final user = AppUser(
        uid: uid,
        email: trimmedEmail,
        college: _selectedCollege ?? '',
        program: _selectedProgram ?? '',
        role: _selectedRole ?? 'Hitcher',
        driverVerified: isDriver ? false : null,
        createdAt: DateTime.now(),
      );

      await _userRepository.saveUser(user);

      if (isDriver) {
        final licenseUrl = _licenseFile == null
            ? null
            : await _storageRepository.uploadFile(
                file: _licenseFile!,
                path: 'driver_docs/$uid/license.jpg',
                contentType: 'image/jpeg',
              );
        final orcrUrl = _orcrFile == null
            ? null
            : await _storageRepository.uploadFile(
                file: _orcrFile!,
                path: 'driver_docs/$uid/orcr.jpg',
                contentType: 'image/jpeg',
              );

        await _userRepository.mergeUserData(uid, {
          'licenseUrl': licenseUrl,
          'orcrUrl': orcrUrl,
        });
      }

      await _authRepository.sendVerificationEmail();
      await _authRepository.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      setError(e.message ?? 'Signup failed.');
      return false;
    } catch (e) {
      setError('Unexpected error: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
