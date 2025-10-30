import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'login_or_signin_page.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _auth = FirebaseAuth.instance;

  bool _emailSent = false; // tracks if we successfully sent at least once
  bool _isSending = false;
  bool _canResend = true;
  bool _navigated = false;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail(); // send on entry
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // Sends email exactly when needed; starts polling after success
  Future<void> _sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Don’t spam if already sending
    if (_isSending) return;

    setState(() => _isSending = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent 📧'),
          backgroundColor: Colors.green,
        ),
      );

      // Start polling *after* initial send
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Poll every 3s to see if user verified; requires backend reload
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = _auth.currentUser;
      if (user == null) return;

      try {
        await user.reload();
      } catch (_) {
        /* ignore transient */
      }

      final refreshed = _auth.currentUser;
      if (mounted && refreshed != null && refreshed.emailVerified) {
        _goToApp();
      }
    });
  }

  // Manual “I’ve verified” button
  Future<void> _manualCheck() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.reload();
    } catch (_) {}

    final refreshed = _auth.currentUser;
    if (refreshed != null && refreshed.emailVerified) {
      _goToApp();
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Email Not Verified'),
          content: Text(
            'Please click the verification link sent to your school email.\n\n'
            'If it expired, tap “Resend Email” to get a new one.',
          ),
        ),
      );
    }
  }

  // Resend with cooldown
  Future<void> _resendVerification() async {
    if (!_canResend) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _canResend = false;
      _isSending = true;
    });

    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent again 📧'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // 30s cooldown
    await Future.delayed(const Duration(seconds: 30));
    if (mounted) setState(() => _canResend = true);
  }

  // When verified, go back through AuthPage (which re-checks)
  void _goToApp() {
    if (_navigated) return;
    _navigated = true;
    _pollTimer?.cancel();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  // Logout: forces them to verify before logging back in
  void _logout() {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginOrSigninPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? "your email";
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4E1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.black),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
        actions: [
          // Optional: re-send from the top bar too
          IconButton(
            onPressed: _canResend ? _resendVerification : null,
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: _canResend ? 'Resend Email' : 'Please wait…',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread,
                  color: Colors.red,
                  size: 90,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verify your email address',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('A verification link was sent to:'),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                if (_isSending)
                  const Text(
                    'Sending verification email...',
                    style: TextStyle(color: Colors.black54),
                  ),
                if (_emailSent && !_isSending)
                  const Text(
                    'Please check your inbox ✉️',
                    style: TextStyle(color: Colors.black54),
                  ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _manualCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(45),
                  ),
                  child: const Text(
                    "I've Verified My Email",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: _canResend ? _resendVerification : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(_canResend ? 'Resend Email' : 'Please wait 30s'),
                ),

                const SizedBox(height: 25),
                const Text(
                  'Note: Only verified emails can log in.\n'
                  'Use the latest verification email — older links may show “expired or used.”',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
