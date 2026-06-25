import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/api/api_client.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(apiClientProvider).post('/api/auth/reset-password', data: {
        'token': widget.token,
        'password': password,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting password: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reset Password')),
        body: const Center(
          child: Text('Invalid password reset link.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter your new password below.'),
            const SizedBox(height: 32),
            CkInput(
              controller: _passwordController,
              label: 'New Password',
              obscureText: true,
              fullWidth: true,
            ),
            const SizedBox(height: 32),
            CkButton(
              onPressed: _isLoading ? null : _submit,
              fullWidth: true,
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}
