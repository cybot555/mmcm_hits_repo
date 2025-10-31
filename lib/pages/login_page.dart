import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/my_button.dart';
import 'package:mmcm_hits/components/my_textfield.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/viewmodels/login_viewmodel.dart';
import 'package:provider/provider.dart';

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(LoginViewModel viewModel) async {
    final success = await viewModel.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!success && mounted && viewModel.errorMessage != null) {
      _showError(viewModel.errorMessage!);
      viewModel.resetError();
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(authRepository),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 248, 175, 168),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "HITS",
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 17, 0),
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                            const SizedBox(height: 20),
                            MyTextfield(
                              controller: emailController,
                              hintText: 'Email',
                              obscureText: false,
                            ),
                            const SizedBox(height: 15),
                            MyTextfield(
                              controller: passwordController,
                              hintText: 'Password',
                              obscureText: true,
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("No account? "),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: widget.onTap,
                                  child: const Text(
                                    "Create an Account",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 255, 17, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            MyButton(
                              onTap: () => _handleLogin(viewModel),
                              isLoading: viewModel.isLoading,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
