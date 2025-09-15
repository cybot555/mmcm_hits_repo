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
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();
  String? selectedCollege;
  String? selectedProgram;
  String? selectedRole;

  void signUpUser(){}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 175, 168), 
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 248, 175, 168),
        leading: BackButton( //back button
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
                            controller: usernameController,
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
                          }
                          );
                         }, colleges: [],
                        ),
          
                        const SizedBox(height: 10),
          
                        // driver or rider radio button
                        DriverOrRider(
                          selectedRole: selectedRole,
                          onChanged: (role){
                            setState(() {
                              selectedRole = role;
                            });
                          }
                        ),
          
                        const SizedBox(height: 1),
                        
                        //driver verificatione
                        if(selectedRole == "Driver")const DriverVerification(),
          
                        const SizedBox(height: 10),
          
                        //signup button
                        GestureDetector(
                          onTap: signUpUser,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "SIGNUP",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
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
