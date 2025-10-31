import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Wraps [FirebaseStorage] interactions so the rest of the app does not deal
/// with storage paths or upload details directly.
class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository(FirebaseStorage storage) : _storage = storage;

  Future<String> uploadFile({
    required File file,
    required String path,
    String? contentType,
  }) async {
    final ref = _storage.ref(path);

    final metadata = contentType == null
        ? null
        : SettableMetadata(contentType: contentType);

    final snapshot = metadata == null
        ? await ref.putFile(file)
        : await ref.putFile(file, metadata);

    if (snapshot.bytesTransferred != snapshot.totalBytes ||
        snapshot.state != TaskState.success) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        message: 'Upload failed at $path',
      );
    }

    return snapshot.ref.getDownloadURL();
  }

  Future<void> deleteFileIfExists(String path) async {
    final ref = _storage.ref(path);
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }
      rethrow;
    }
  }
}
