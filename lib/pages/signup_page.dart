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

  final AuthService _authService = AuthService();

  // -----------------------------
  // SIGNUP LOGIC
  // -----------------------------
  Future<void> signUpUser() async {
    setState(() => _isLoading = true);

    try {
      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text.trim();
      final confirmPassword = confirmpasswordController.text.trim();

      // ✅ School email restriction
      if (!email.endsWith('@mcm.edu.ph')) {
        setState(() => _isLoading = false);
        showErrorMessage("Invalid Email");
        return;
      }

      // ✅ Password match check
      if (password != confirmPassword) {
        setState(() => _isLoading = false);
        showErrorMessage("Passwords don't match!");
        return;
      }

      // ✅ Require driver docs if Driver
      if (selectedRole == "Driver" && !driverDocsReady) {
        setState(() => _isLoading = false);
        showErrorMessage(
          "Please upload both License and OR/CR to register as a Driver!",
        );
        return;
      }

      // ✅ Create account
      final userCredential = await _authService.registerWithEmail(email, password);
      final uid = userCredential.user!.uid;

      // ✅ Save user info to Firestore
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

      // ✅ Send verification email
      await _authService.sendEmailVerification();

      if (!mounted) return;

      // ✅ Stop loading and move to verification page
      setState(() => _isLoading = false);
      await Future.delayed(const Duration(milliseconds: 150));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      showErrorMessage(e.message ?? "Something went wrong");
    }
  }

  // -----------------------------
  // ERROR POPUP
  // -----------------------------
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

  // -----------------------------
  // UI
  // -----------------------------
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
                      ),

                    const SizedBox(height: 25),

                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : (selectedRole == "Driver" && !driverDocsReady)
                              ? null
                              : signUpUser,
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