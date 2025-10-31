import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mmcm_hits/pages/home.dart';
import 'package:mmcm_hits/pages/login_or_signin_page.dart';
import 'package:mmcm_hits/pages/email_verification_page.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(authRepository),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: viewModel.authState,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const LoginOrSigninPage();
          }

          final user = snapshot.data!;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.refreshUserIfNeeded(user);
          });

          final currentUser = viewModel.currentUser ?? user;

          if (!(currentUser.emailVerified)) {
            return const EmailVerificationPage();
          }

          return HomePage(uid: currentUser.uid);
        },
      ),
    );
  }
}
