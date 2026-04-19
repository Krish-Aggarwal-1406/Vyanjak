import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/primary_button.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  bool _googleLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _auth.signInWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found')) return 'No account found with this email.';
    if (raw.contains('wrong-password')) return 'Incorrect password.';
    if (raw.contains('invalid-email')) return 'Invalid email address.';
    if (raw.contains('network-request-failed')) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.frostyWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                'Welcome\nback.',
                style: GoogleFonts.dancingScript(
                  color: AppTheme.spaceNavy,
                  fontSize: 58,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text('Sign in to continue your recovery journey.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textCharcoal.withOpacity(0.6))),
              const SizedBox(height: 48),
              _inputField('Email', _emailCtrl,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _inputField('Password', _passCtrl, obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppTheme.errorRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Sign In',
                onPressed: _login,
                isLoading: _isLoading,
                icon: Icons.login_rounded,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _googleLoading ? null : _googleLogin,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.spaceNavy.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _googleLoading
                      ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.spaceNavy))
                      : Image.network(
                      'https://www.google.com/favicon.ico',
                      height: 20, width: 20),
                  label: const Text('Continue with Google',
                      style: TextStyle(
                          color: AppTheme.spaceNavy,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Don't have an account? ",
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text('Sign up',
                      style: TextStyle(
                          color: AppTheme.electricTeal,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl,
      {bool obscure = false,
        TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.spaceNavy,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppTheme.spaceNavy, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.pureWhite,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: AppTheme.electricTeal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}