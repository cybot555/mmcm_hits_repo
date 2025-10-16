import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/pages/home.dart';
import 'package:mmcm_hits/pages/login_or_signin_page.dart';
import 'package:mmcm_hits/pages/email_verification_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // ✅ User logged in
          if (snapshot.hasData) {
            final user = FirebaseAuth.instance.currentUser!;

            // ✅ Check if email is verified
            if (!user.emailVerified) {
              return const EmailVerificationPage();
            } else {
              return const HomePage();
            }
          }

          // ❌ User not logged in
          return const LoginOrSigninPage();
        },
      ),
    );
  }
}