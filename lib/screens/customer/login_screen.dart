import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// The single login page for everyone. Customers and staff sign in here;
/// AuthGate sends each account to the right side based on its Firestore role.
class LoginScreen extends StatefulWidget {
  /// Kept so existing callers still compile; AuthGate now handles routing.
  final bool returnToCheckout;
  const LoginScreen({super.key, this.returnToCheckout = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  bool _registerMode = false;
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppState>().customerAuth;
    setState(() => _busy = true);
    final user = _registerMode
        ? await auth.registerEmail(
            name: _nameController.text.trim(),
            email: _emailController.text,
            password: _passwordController.text,
            contact: _contactController.text.trim(),
          )
        : await auth.signinEmail(_emailController.text, _passwordController.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (user == null) showErrorSnack(context, auth.lastError ?? 'Something went wrong.');
    // On success AuthGate takes over: customer -> menu, staff -> dashboard,
    // new/unverified customer -> verify-email screen.
  }

  Future<void> _google() async {
    final auth = context.read<AppState>().customerAuth;
    setState(() => _busy = true);
    final user = await auth.signinGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (user == null && auth.lastError != null) showErrorSnack(context, auth.lastError!);
  }

  Future<void> _forgot() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      showErrorSnack(context, 'Enter your email above first.');
      return;
    }
    final auth = context.read<AppState>().customerAuth;
    final ok = await auth.resetPassword(email);
    if (!mounted) return;
    if (ok) {
      showSuccessSnack(context, 'Password reset link sent to $email.');
    } else {
      showErrorSnack(context, auth.lastError ?? 'Could not send the reset link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.cake_rounded, color: AppColors.ribbonRed, size: 64),
                const SizedBox(height: 10),
                Text(
                  _registerMode ? 'Create your account' : 'Welcome back!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (_registerMode) ...[
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                if (!_registerMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: _forgot, child: const Text('Forgot Password?')),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_registerMode ? 'Register' : 'Login'),
                ),
                const SizedBox(height: 14),
                Row(children: const [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or')),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _google,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => setState(() => _registerMode = !_registerMode),
                    child: Text(_registerMode ? 'Already have an account? Log In' : 'New here? Create an account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}