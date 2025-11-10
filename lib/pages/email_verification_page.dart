import 'package:flutter/material.dart';
import 'package:mmcm_hits/pages/auth_page.dart';
import 'package:mmcm_hits/pages/login_or_signin_page.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/viewmodels/email_verification_viewmodel.dart';
import 'package:provider/provider.dart';

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    return ChangeNotifierProvider(
      create: (_) => EmailVerificationViewModel(authRepository),
      child: const _EmailVerificationView(),
    );
  }
}

class _EmailVerificationView extends StatefulWidget {
  const _EmailVerificationView();

  @override
  State<_EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<_EmailVerificationView> {
  bool _navigated = false;
  EmailVerificationViewModel? _lastViewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<EmailVerificationViewModel>();
    if (!identical(_lastViewModel, viewModel)) {
      _lastViewModel = viewModel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        viewModel.ensureInitialEmailSent();
      });
    }
  }

  void _showMessage(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _handleManualCheck(
    EmailVerificationViewModel viewModel,
  ) async {
    final verified = await viewModel.checkIfVerified();
    if (!verified && mounted) {
      showDialog<void>(
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

  Future<void> _handleResend(EmailVerificationViewModel viewModel) async {
    await viewModel.resendVerificationEmail();
    if (!mounted) return;

    if (viewModel.errorMessage != null) {
      _showMessage(viewModel.errorMessage!, success: false);
      viewModel.resetError();
    } else {
      _showMessage('Verification email sent 📧');
    }
  }

  Future<void> _handleLogout(EmailVerificationViewModel viewModel) async {
    await viewModel.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginOrSigninPage()),
    );
  }

  void _navigateToApp() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmailVerificationViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isVerified) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToApp());
        }

        if (viewModel.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMessage(viewModel.errorMessage!, success: false);
            viewModel.resetError();
          });
        }

        final email = viewModel.currentUser?.email ?? 'your email';
        final isSending = viewModel.isSending;
        final canResend = viewModel.canResend && !isSending;

        return Scaffold(
          backgroundColor: const Color(0xFFFFE4E1),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFE4E1),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () => _handleLogout(viewModel),
              tooltip: 'Logout',
            ),
            actions: [
              IconButton(
                onPressed: canResend ? () => _handleResend(viewModel) : null,
                icon: const Icon(Icons.refresh, color: Colors.black),
                tooltip: canResend ? 'Resend Email' : 'Please wait…',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'A verification link has been sent to:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please check your inbox (or spam folder) and click the link to verify.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(45),
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed:
                      isSending ? null : () => _handleManualCheck(viewModel),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('I have verified my email'),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(45),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: canResend ? () => _handleResend(viewModel) : null,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Resend Verification Email'),
                ),
                const SizedBox(height: 30),
                if (viewModel.emailSent)
                  const Text(
                    'Already sent! You can resend after 30 seconds.',
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
