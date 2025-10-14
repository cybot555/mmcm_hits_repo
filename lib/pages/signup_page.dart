import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/my_textfield.dart';
import 'package:mmcm_hits/components/my_college_dropdown.dart';
import 'package:mmcm_hits/components/driver_or_rider.dart';
import 'package:mmcm_hits/components/driver_verification.dart';

class SignupPage extends StatefulWidget {
  final Function()? onTap;
  const SignupPage({super.key, required this.onTap});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Firebase + controllers
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();

  String? selectedCollege;
  String? selectedProgram;
  String? selectedRole;
  bool driverDocsReady = false; // ✅ Track if both license & OR/CR uploaded

  // -----------------------------
  // SIGNUP LOGIC
  // -----------------------------
  Future<void> signUpUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Password check
      if (passwordController.text != confirmpasswordController.text) {
        Navigator.pop(context);
        showErrorMessage("Passwords don't match!");
        return;
      }

      // ✅ Require uploads for Driver role
      if (selectedRole == "Driver" && !driverDocsReady) {
        Navigator.pop(context);
        showErrorMessage(
          "Please upload both License and OR/CR to register as a Driver!",
        );
        return;
      }

      // Create account
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final uid = userCredential.user!.uid;

      // Save user data to Firestore
      await db.collection('users').doc(uid).set({
        'uid': uid,
        'email': emailController.text.trim(),
        'college': selectedCollege ?? '',
        'program': selectedProgram ?? '',
        'role': selectedRole ?? 'Hitcher',
        'driverVerified': selectedRole == "Driver" ? false : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // close loading

      // Redirect after sign up
      Navigator.pushReplacementNamed(context, "/home");
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showErrorMessage(e.code);
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

                    // EMAIL
                    MyTextfield(
                      controller: emailController,
                      hintText: 'Email',
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),

                    // PASSWORD
                    MyTextfield(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),

                    // CONFIRM PASSWORD
                    MyTextfield(
                      controller: confirmpasswordController,
                      hintText: 'Confirm Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),

                    // COLLEGE + PROGRAM
                    MyCollegeDropdown(
                      onChanged: (college, program) {
                        setState(() {
                          selectedCollege = college;
                          selectedProgram = program;
                        });
                      },
                      colleges: [],
                    ),
                    const SizedBox(height: 10),

                    // DRIVER OR HITCHER
                    DriverOrRider(
                      selectedRole: selectedRole,
                      onChanged: (role) {
                        setState(() {
                          selectedRole = role;
                        });
                      },
                    ),

                    // DRIVER VERIFICATION
                    if (selectedRole == "Driver")
                      DriverVerification(
                        onVerificationChanged: (ready) {
                          setState(() {
                            driverDocsReady = ready;
                          });
                        },
                      ),

                    const SizedBox(height: 20),

                    // SIGN UP BUTTON
                    GestureDetector(
                      onTap: (selectedRole == "Driver" && !driverDocsReady)
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
                          child: const Center(
                            child: Text(
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
