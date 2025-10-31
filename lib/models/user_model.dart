import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String college;
  final String program;
  final String role;
  final bool? driverVerified;
  final DateTime createdAt;
  final String? name;
  final String? phone;
  final String? plateNumber;
  final String? carBrand;
  final String? otherBrand;
  final String? carModel;
  final String? profileImage;
  final String? profileImagePath;
  final String? licenseUrl;
  final String? orcrUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.college,
    required this.program,
    required this.role,
    this.driverVerified,
    required this.createdAt,
    this.name,
    this.phone,
    this.plateNumber,
    this.carBrand,
    this.otherBrand,
    this.carModel,
    this.profileImage,
    this.profileImagePath,
    this.licenseUrl,
    this.orcrUrl,
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
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (plateNumber != null) 'plateNumber': plateNumber,
      if (carBrand != null) 'carBrand': carBrand,
      if (otherBrand != null) 'otherBrand': otherBrand,
      if (carModel != null) 'carModel': carModel,
      if (profileImage != null) 'profileImage': profileImage,
      if (profileImagePath != null) 'profileImagePath': profileImagePath,
      if (licenseUrl != null) 'licenseUrl': licenseUrl,
      if (orcrUrl != null) 'orcrUrl': orcrUrl,
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
      name: map['name'],
      phone: map['phone'],
      plateNumber: map['plateNumber'],
      carBrand: map['carBrand'],
      otherBrand: map['otherBrand'],
      carModel: map['carModel'],
      profileImage: map['profileImage'],
      profileImagePath: map['profileImagePath'],
      licenseUrl: map['licenseUrl'],
      orcrUrl: map['orcrUrl'],
    );
  }
}
