import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mmcm_hits/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -----------------------------
  // REGISTER USER
  // -----------------------------
  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // -----------------------------
  // SAVE USER TO FIRESTORE
  // -----------------------------
  Future<void> saveUserToFirestore(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  // -----------------------------
  // SEND EMAIL VERIFICATION
  // -----------------------------
  Future<void> sendEmailVerification() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && !currentUser.emailVerified) {
      await currentUser.sendEmailVerification();
    }
  }

  // -----------------------------
  // CHECK IF EMAIL IS VERIFIED
  // -----------------------------
  Future<bool> isEmailVerified() async {
    final currentUser = _auth.currentUser;
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
  }
}