import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mmcm_hits/models/user_model.dart';

/// Data access layer for the `users` Firestore collection.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(FirebaseFirestore firestore) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromMap({...data, 'uid': doc.id});
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return AppUser.fromMap({...data, 'uid': doc.id});
    });
  }

  Stream<Map<String, dynamic>?> watchUserData(String uid) {
    return _users.doc(uid).snapshots().map((doc) => doc.data());
  }

  Future<void> saveUser(AppUser user) {
    return _users.doc(user.uid).set(user.toMap());
  }

  Future<void> mergeUserData(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchRawUserDoc(
    String uid,
  ) {
    return _users.doc(uid).get();
  }
}
