import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'customer/customer_shell.dart';
import 'customer/login_screen.dart';
import 'staff/staff_shell.dart';

/// The single entry point. Whoever signs in is sent to the right side
/// based on the `role` field in their Firestore `users/{uid}` document:
///   role == 'customer' -> customer pages
///   role == 'staff'    -> staff pages
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AppState, AuthStatus>((s) => s.authStatus);

    switch (status) {
      case AuthStatus.initializing:
      case AuthStatus.loadingProfile:
        return const Scaffold(
          backgroundColor: AppColors.cream,
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.unverified:
        return const _VerifyEmailScreen();
      case AuthStatus.customer:
        return const CustomerShell();
      case AuthStatus.staff:
        return const StaffShell();
    }
  }
}

class _VerifyEmailScreen extends StatefulWidget {
  const _VerifyEmailScreen();

  @override
  State<_VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<_VerifyEmailScreen> {
  bool _busy = false;

  Future<void> _resend() async {
    final appState = context.read<AppState>();
    setState(() => _busy = true);
    final ok = await appState.customerAuth.resendVerification();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      showSuccessSnack(context, 'Verification email sent.');
    } else {
      showErrorSnack(context, appState.customerAuth.lastError ?? 'Could not send the email.');
    }
  }

  Future<void> _check() async {
    final appState = context.read<AppState>();
    setState(() => _busy = true);
    await appState.recheckVerification();
    if (!mounted) return;
    setState(() => _busy = false);
    if (appState.authStatus == AuthStatus.unverified) {
      showErrorSnack(context, 'Email not verified yet. Check your inbox.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<AppState>().customerAuth.currentUser?.email ?? 'your email';
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 64, color: AppColors.ribbonRed),
                const SizedBox(height: 16),
                Text('Verify your email', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('We sent a verification link to $email.',
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _check,
                    child: const Text("I've verified my email"),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _resend,
                    child: const Text('Resend email'),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<AppState>().logout(),
                  child: const Text('Use a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}