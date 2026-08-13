import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common_widgets.dart';

/// Sends a real Supabase password-recovery email. Supabase handles the
/// actual reset link + new-password entry on its own hosted page (or a
/// deep link back into this app, if one is configured in the Supabase
/// dashboard's Auth → URL Configuration settings).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.sendPasswordResetEmail(_email.text);
    if (!mounted) return;
    if (result.success) {
      setState(() => _sent = true);
    } else {
      showAppSnackBar(context, result.error ?? 'Could not send reset email', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccess(context) : _buildForm(context, auth),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 48),
          const SizedBox(height: 16),
          Text(
            "Enter your account email and we'll send you a secure reset link.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _email,
            label: 'Email',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
              if (!regex.hasMatch(v.trim())) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Send Reset Link', isLoading: auth.isLoading, onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.mark_email_read_rounded, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        Text('Check your inbox', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'We sent a password reset link to ${_email.text.trim()}. Follow it to choose a new password.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppButton(label: 'Back to Login', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
