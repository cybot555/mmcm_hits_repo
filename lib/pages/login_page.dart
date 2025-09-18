import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/my_button.dart';
import 'package:mmcm_hits/components/my_textfield.dart';


class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //log user in method
void logUserIn() async {
  // show loading circle
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

    try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
   );

    if (!mounted) return; // ✅ prevent calling context if unmounted
    Navigator.pop(context); // close loading
  }   
    on FirebaseAuthException catch (e) {
      if (!mounted) return; // ✅ same here
        Navigator.pop(context); // close loading first

      showErrorMessage(e.code);
  }
}

//show error message
Future<void> showErrorMessage(String message) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.blue,
        title: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      );
    },
  );
}






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 175, 168), 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
            
                const SizedBox(height: 20),
            
                // White card container
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
                      // Logo
                      const Icon(
                        Icons.directions_car,
                        color: Colors.red,
                        size: 60,
                      ),
            
                      const SizedBox(height: 20),
            
                      // Email textfield
                      MyTextfield(
                        controller: emailController,
                        hintText: 'Email',
                        obscureText: false,
                      ),
            
                      const SizedBox(height: 15),
            
                      // Password textfield
                      MyTextfield(
                        controller: passwordController,
                        hintText: 'Password',
                        obscureText: true,
                      ),
            
                      const SizedBox(height: 15),
            
                      // "No account?" text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Text("No account? "),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: const Text(
                              "Create an Account",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
            
                      const SizedBox(height: 20),
            
                      // Login button
                      MyButton(
                        onTap: logUserIn,
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
