import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String college;
  final String program;
  final String role;
  final bool? driverVerified;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.college,
    required this.program,
    required this.role,
    this.driverVerified,
    required this.createdAt,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'college': college,
      'program': program,
      'role': role,
      'driverVerified': driverVerified,
      'createdAt': createdAt,
    };
  }

  // Create from map (if needed later)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      college: map['college'] ?? '',
      program: map['program'] ?? '',
      role: map['role'] ?? '',
      driverVerified: map['driverVerified'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}