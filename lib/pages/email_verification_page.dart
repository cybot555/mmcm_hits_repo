import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/pages/auth_page.dart';
import 'package:mmcm_hits/pages/login_or_signin_page.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _canResend = true;
  bool _isSending = false;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _sendInitialVerificationEmail();
  }

  // ✅ Send verification email on page load
  Future<void> _sendInitialVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      setState(() => _isSending = true);
      await user.sendEmailVerification();
      setState(() => _isSending = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent 📧"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

    // ✅ Manual check verification (strict + real-time refresh)
  Future<void> _checkVerification() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("Error"),
            content: Text("No user is currently logged in."),
          ),
        );
        return;
      }

      // 🔄 Force a fresh reload from Firebase servers
      await user.reload();
      final refreshedUser = _auth.currentUser;

      // ⏳ Wait a bit to ensure the verification status propagates
      await Future.delayed(const Duration(seconds: 1));

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // ✅ Proceed only if truly verified
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthPage()),
          );
        }
      } else {
        // ❌ Not verified yet or expired
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => const AlertDialog(
              title: Text("Email Not Verified"),
              content: Text(
                "Please make sure you clicked the verification link sent to your school email.\n\n"
                "If the link has expired, tap 'Resend Email' to get a new one.",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text("An error occurred: $e"),
          ),
        );
      }
    }
  }

  // ✅ Resend verification email with 10s cooldown
  Future<void> _resendVerification() async {
    final user = _auth.currentUser;
    if (user != null && _canResend) {
      setState(() {
        _canResend = false;
        _isSending = true;
      });

      await user.sendEmailVerification();
      setState(() => _isSending = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent again 📧"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 10));
      if (mounted) setState(() => _canResend = true);
    }
  }

  // ✅ Back to login
  void _goBackToLogin() {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginOrSigninPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? "your school email";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 175, 168),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 248, 175, 168),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _goBackToLogin,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, color: Colors.red, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Verify your email",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text("A verification link was sent to:"),
              const SizedBox(height: 5),
              Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),

              if (_isSending)
                const Text(
                  "Sending verification email...",
                  style: TextStyle(color: Colors.black54),
                ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: _checkVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  "I've Verified My Email",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: _canResend ? _resendVerification : null,
                child: Text(
                  _canResend ? "Resend Email" : "Wait 10s to resend",
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}