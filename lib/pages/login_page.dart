import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/my_textfield.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  // text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // log user in method
  void logUserIn() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 175, 168),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              const Text(
                "HITS",
                style: TextStyle(
                  color: Color.fromARGB(255, 205, 1, 1),
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
                  borderRadius: BorderRadius.circular(25),
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
                      controller: usernameController,
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
                      children: const [
                        Text("No account? "),
                        Text(
                          "Create an Account",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Login button
                    GestureDetector(
                      onTap: logUserIn,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 104, 106, 255),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Center(
                          child: Text(
                            "LOGIN",
                            style: TextStyle(
                              color: Colors.white,
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
      ),
    );
  }
}
