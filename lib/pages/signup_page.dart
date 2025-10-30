import 'dart:io'; // ⬅️ NEW
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/my_textfield.dart';
import 'package:mmcm_hits/components/my_college_dropdown.dart';
import 'package:mmcm_hits/components/driver_or_rider.dart';
import 'package:mmcm_hits/components/driver_verification.dart';
import 'package:mmcm_hits/services/auth_service.dart';
import 'package:mmcm_hits/models/user_model.dart';
import 'package:mmcm_hits/pages/email_verification_page.dart';
import 'package:firebase_storage/firebase_storage.dart'; // ⬅️ NEW

class SignupPage extends StatefulWidget {
  final Function()? onTap;
  const SignupPage({super.key, required this.onTap});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();

  String? selectedCollege;
  String? selectedProgram;
  String? selectedRole;
  bool driverDocsReady = false;
  bool _isLoading = false;

  // ⬅️ NEW: hold picked files from DriverVerification
  File? _licenseFile;
  File? _orcrFile;

  final AuthService _authService = AuthService();

  /// -----------------------------
  /// SIGNUP LOGIC
  /// -----------------------------
  Future<void> signUpUser() async {
    setState(() => _isLoading = true);

    try {
      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text.trim();
      final confirmPassword = confirmpasswordController.text.trim();

      // ✅ School email restriction
      if (!email.endsWith('@mcm.edu.ph')) {
        setState(() => _isLoading = false);
        showErrorMessage("Please use your school email (@mcm.edu.ph)");
        return;
      }

      // ✅ Password match check
      if (password != confirmPassword) {
        setState(() => _isLoading = false);
        showErrorMessage("Passwords don't match!");
        return;
      }

      // ✅ Role-specific validation
      if (selectedRole == null) {
        setState(() => _isLoading = false);
        showErrorMessage("Please select your role (Driver or Hitcher).");
        return;
      }

      // ✅ Require driver docs if Driver
      if (selectedRole == "Driver" &&
          (_licenseFile == null || _orcrFile == null)) {
        setState(() => _isLoading = false);
        showErrorMessage("Upload both License and OR/CR before signing up!");
        return;
      }

      // ✅ Create Firebase user account
      final userCredential = await _authService.registerWithEmail(
        email,
        password,
      );
      final user = userCredential.user!;
      final uid = user.uid;

      // ✅ Save initial user data to Firestore
      final appUser = AppUser(
        uid: uid,
        email: email,
        college: selectedCollege ?? '',
        program: selectedProgram ?? '',
        role: selectedRole ?? 'Hitcher',
        driverVerified: selectedRole == "Driver" ? false : null,
        createdAt: DateTime.now(),
      );
      await _authService.saveUserToFirestore(appUser);

      // ✅ If Driver: upload docs to Storage, store URLs on user doc
      if (selectedRole == "Driver") {
        String? licenseUrl;
        String? orcrUrl;

        final storage = FirebaseStorage.instance;

        // License
        if (_licenseFile != null) {
          final licRef = storage.ref().child('driver_docs/$uid/license.jpg');
          await licRef.putFile(_licenseFile!);
          licenseUrl = await licRef.getDownloadURL();
        }

        // OR/CR
        if (_orcrFile != null) {
          final orcrRef = storage.ref().child('driver_docs/$uid/orcr.jpg');
          await orcrRef.putFile(_orcrFile!);
          orcrUrl = await orcrRef.getDownloadURL();
        }

        // Merge URLs into user doc
        await db.collection('users').doc(uid).set({
          'licenseUrl': licenseUrl,
          'orcrUrl': orcrUrl,
        }, SetOptions(merge: true));
      }

      // ✅ Send verification email
      await _authService.sendEmailVerification();

      // ✅ Sign out right away so they can’t enter without verifying
      await FirebaseAuth.instance.signOut();

      // ✅ Move to email verification page
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      showErrorMessage(e.message ?? "Something went wrong during signup");
    }
  }

  /// -----------------------------
  /// ERROR POPUP
  /// -----------------------------
  Future<void> showErrorMessage(String message) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  }

  /// -----------------------------
  /// UI
  /// -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 175, 168),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 248, 175, 168),
        leading: BackButton(onPressed: widget.onTap, color: Colors.red),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "HITS",
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 17, 0),
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icons/map.png',
                      width: 65,
                      height: 65,
                      fit: BoxFit.fitHeight,
                    ),
                    const SizedBox(height: 25),

                    MyTextfield(
                      controller: emailController,
                      hintText: 'School Email',
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),

                    MyTextfield(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),

                    MyTextfield(
                      controller: confirmpasswordController,
                      hintText: 'Confirm Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),

                    MyCollegeDropdown(
                      onChanged: (college, program) {
                        setState(() {
                          selectedCollege = college;
                          selectedProgram = program;
                        });
                      },
                      colleges: [],
                    ),
                    const SizedBox(height: 20),

                    DriverOrRider(
                      selectedRole: selectedRole,
                      onChanged: (role) {
                        setState(() {
                          selectedRole = role;
                        });
                      },
                    ),

                    if (selectedRole == "Driver")
                      DriverVerification(
                        onVerificationChanged: (ready) {
                          setState(() {
                            driverDocsReady = ready;
                          });
                        },
                        // ⬇️ NEW: capture picked files (no UI change)
                        onFilesChanged: (license, orcr) {
                          _licenseFile = license;
                          _orcrFile = orcr;
                        },
                      ),

                    const SizedBox(height: 25),

                    GestureDetector(
                      onTap: _isLoading ? null : signUpUser,
                      child: Opacity(
                        opacity: (selectedRole == "Driver" && !driverDocsReady)
                            ? 0.5
                            : 1.0,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 0, 255, 8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.blue,
                                    ),
                                  )
                                : const Text(
                                    "SIGNUP",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 68, 255),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
