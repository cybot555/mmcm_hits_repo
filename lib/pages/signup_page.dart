import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/my_textfield.dart';
import 'package:mmcm_hits/components/my_college_dropdown.dart';
import 'package:mmcm_hits/components/driver_or_rider.dart';
import 'package:mmcm_hits/components/driver_verification.dart';
import 'package:mmcm_hits/pages/email_verification_page.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/storage_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/signup_viewmodel.dart';
import 'package:provider/provider.dart';

class SignupPage extends StatefulWidget {
  final Function()? onTap;
  const SignupPage({super.key, required this.onTap});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup(SignupViewModel viewModel) async {
    final success = await viewModel.register(
      email: emailController.text,
      password: passwordController.text,
      confirmPassword: confirmpasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
      );
    } else if (viewModel.errorMessage != null) {
      _showError(viewModel.errorMessage!);
      viewModel.resetError();
    }
  }

  Future<void> _showError(String message) async {
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
    final authRepository = context.read<AuthRepository>();
    final userRepository = context.read<UserRepository>();
    final storageRepository = context.read<StorageRepository>();

    return ChangeNotifierProvider(
      create: (_) => SignupViewModel(
        authRepository: authRepository,
        userRepository: userRepository,
        storageRepository: storageRepository,
      ),
      child: Consumer<SignupViewModel>(
        builder: (context, viewModel, _) {
          final isDriver = viewModel.isDriver;
          final buttonEnabled = !viewModel.isLoading &&
              (!isDriver || viewModel.driverDocsReady);

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
                            onChanged: viewModel.updateCollegeAndProgram,
                            colleges: const [],
                          ),
                          const SizedBox(height: 20),
                          DriverOrRider(
                            selectedRole: viewModel.selectedRole,
                            onChanged: viewModel.updateRole,
                          ),
                          if (isDriver)
                            DriverVerification(
                              onVerificationChanged: (_) {},
                              onFilesChanged: (license, orcr) {
                                viewModel.updateDriverDocuments(
                                  license: license,
                                  orcr: orcr,
                                );
                              },
                            ),
                          const SizedBox(height: 25),
                          GestureDetector(
                            onTap: buttonEnabled
                                ? () => _handleSignup(viewModel)
                                : null,
                            child: Opacity(
                              opacity: buttonEnabled ? 1.0 : 0.5,
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 0, 255, 8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: viewModel.isLoading
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
                                            color: Color.fromARGB(
                                              255,
                                              0,
                                              68,
                                              255,
                                            ),
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
        },
      ),
    );
  }
}
