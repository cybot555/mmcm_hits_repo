import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/my_textfield.dart';
import 'package:mmcm_hits/components/my_college_dropdown.dart';
import 'package:mmcm_hits/components/driver_or_rider.dart';
import 'package:mmcm_hits/components/driver_verification.dart';

class SignupPage extends StatefulWidget {
  final Function()? onTap;
  SignupPage({super.key, required this.onTap});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();
  String? selectedCollege;
  String? selectedProgram;
  String? selectedRole;

  void signUpUser() async {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent dismissing by tapping outside
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      if (passwordController.text != confirmpasswordController.text) {
        if (!mounted) return;
        Navigator.pop(context); // close loading first
        showErrorMessage("Passwords don't match!");
        return;
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context); // close loading
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      showErrorMessage(e.code);
    }
  }

  Future<void> showErrorMessage(String message) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blue,
          title: Center(
            child: Text(message, style: const TextStyle(color: Colors.black)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 175, 168),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 248, 175, 168),
        leading: BackButton(
          //back button
          onPressed: widget.onTap,
          color: Colors.red,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      "HITS",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 100,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // White card container
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      padding: const EdgeInsets.all(10),
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
                          // Logo
                          const Icon(
                            Icons.directions_car,
                            color: Colors.red,
                            size: 60,
                          ),

                          const SizedBox(height: 10),

                          // Email textfield
                          MyTextfield(
                            controller: emailController,
                            hintText: 'Email',
                            obscureText: false,
                          ),

                          const SizedBox(height: 10),

                          // Password textfield
                          MyTextfield(
                            controller: passwordController,
                            hintText: 'Password',
                            obscureText: true,
                          ),

                          const SizedBox(height: 10),

                          //confirm password txtfield
                          MyTextfield(
                            controller: confirmpasswordController,
                            hintText: 'Confirm Password',
                            obscureText: true,
                          ),

                          const SizedBox(height: 10),

                          //colleges and course dropdown
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

                          // driver or rider radio button
                          DriverOrRider(
                            selectedRole: selectedRole,
                            onChanged: (role) {
                              setState(() {
                                selectedRole = role;
                              });
                            },
                          ),

                          const SizedBox(height: 1),

                          //driver verificatione
                          if (selectedRole == "Driver")
                            const DriverVerification(),

                          const SizedBox(height: 10),

                          //signup button
                          GestureDetector(
                            onTap: signUpUser,
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
                        ],
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
