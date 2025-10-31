import 'dart:async';
import 'dart:io';

import 'package:mmcm_hits/repositories/storage_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class ProfileViewModel extends BaseViewModel {
  ProfileViewModel({
    required UserRepository userRepository,
    required StorageRepository storageRepository,
    required this.uid,
  })  : _userRepository = userRepository,
        _storageRepository = storageRepository;

  final UserRepository _userRepository;
  final StorageRepository _storageRepository;
  final String uid;

  Map<String, dynamic>? _userData;
  StreamSubscription<Map<String, dynamic>?>? _subscription;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  Map<String, dynamic>? get userData => _userData;
  String get role => (_userData?['role'] as String?) ?? '';
  bool get isSaving => _isSaving;
  bool get isUploadingImage => _isUploadingImage;

  void initialise() {
    _subscription ??= _userRepository.watchUserData(uid).listen((data) {
      _userData = data;
      notifyListeners();
    });
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _userRepository.mergeUserData(uid, data);
    } catch (e) {
      setError('Failed to update profile.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> uploadProfilePhoto(File file) async {
    _isUploadingImage = true;
    notifyListeners();
    try {
      final previousPath =
          (_userData?['profileImagePath'] as String?)?.trim();

      final extension = _detectFileExtension(file.path);
      final storagePath =
          'profile_pictures/$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';

      final url = await _storageRepository.uploadFile(
        file: file,
        path: storagePath,
        contentType: _contentTypeForExtension(extension),
      );

      if (previousPath != null && previousPath.isNotEmpty) {
        try {
          await _storageRepository.deleteFileIfExists(previousPath);
        } catch (_) {
          // Ignore cleanup errors; the new image is already uploaded.
        }
      }

      await _userRepository.mergeUserData(uid, {
        'profileImage': url,
        'profileImagePath': storagePath,
      });
      final updatedData = Map<String, dynamic>.from(_userData ?? {});
      updatedData['profileImage'] = url;
      updatedData['profileImagePath'] = storagePath;
      _userData = updatedData;
      notifyListeners();
      return url;
    } catch (e) {
      setError('Error uploading image.');
      return null;
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _detectFileExtension(String path) {
    final segments = path.split('.');
    if (segments.length < 2) return 'jpg';
    final ext = segments.last.toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'heic', 'webp'};
    return allowed.contains(ext) ? ext : 'jpg';
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
