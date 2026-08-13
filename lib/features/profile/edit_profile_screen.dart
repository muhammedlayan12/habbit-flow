import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AuthProvider>().currentUser?.fullName ?? '');
  late final _goal =
      TextEditingController(text: context.read<AuthProvider>().currentUser?.productivityGoal ?? '');
  bool _saving = false;

  final _pwFormKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  bool _changingPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AuthProvider>().updateProfile(
          fullName: _name.text.trim(),
          productivityGoal: _goal.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    showAppSnackBar(context, 'Profile updated');
    Navigator.of(context).pop();
  }

  Future<void> _changePassword() async {
    if (!_pwFormKey.currentState!.validate()) return;
    setState(() => _changingPassword = true);
    final result = await context.read<AuthProvider>().changePassword(_newPassword.text);
    if (!mounted) return;
    setState(() => _changingPassword = false);
    if (result.success) {
      _newPassword.clear();
      showAppSnackBar(context, 'Password updated');
    } else {
      showAppSnackBar(context, result.error ?? 'Could not update password', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _name,
                    label: 'Full name',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _goal,
                    label: 'Productivity goal',
                    prefixIcon: Icons.flag_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  AppButton(label: 'Save Changes', isLoading: _saving, onPressed: _save),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Form(
              key: _pwFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _newPassword,
                    label: 'New password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Update Password',
                    outlined: true,
                    isLoading: _changingPassword,
                    onPressed: _changePassword,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
