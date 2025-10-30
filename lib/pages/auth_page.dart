import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/pages/home.dart';
import 'package:mmcm_hits/pages/login_or_signin_page.dart';
import 'package:mmcm_hits/pages/email_verification_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _auth = FirebaseAuth.instance;
  bool _reloading = false;

  Future<User?> _reloadAndGetUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    try {
      setState(() => _reloading = true);
      await u.reload(); // <-- ensure we aren’t using stale cached data
    } catch (_) {
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
    return _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // userChanges emits when reload() changes fields like emailVerified
        stream: _auth.userChanges(),
        builder: (context, snapshot) {
          // Not logged in -> go to login/signup
          if (!snapshot.hasData) return const LoginOrSigninPage();

          // Logged in: force a one-shot reload before deciding
          return FutureBuilder<User?>(
            future: _reloadAndGetUser(),
            builder: (context, snap) {
              final user = _auth.currentUser;

              // Show a tiny loader while we force-refresh user state
              if (snap.connectionState == ConnectionState.waiting ||
                  _reloading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (user == null) return const LoginOrSigninPage();

              // Gate strictly by emailVerified
              if (!user.emailVerified) {
                return const EmailVerificationPage();
              }

              // Verified -> home
              return const HomePage();
            },
          );
        },
      ),
    );
  }
}
