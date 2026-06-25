import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/api/api_client.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(apiClientProvider).post('/api/auth/forgot-password', data: {
        'email': email,
      });
      setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reset email: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _emailSent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64, color: CookestTokens.colorPrimaryDEFAULT),
                  const SizedBox(height: 32),
                  Text(
                    'Email Sent!',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'If an account exists with that email, a password reset link has been sent.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  CkButton(
                    onPressed: () => context.go('/login'),
                    fullWidth: true,
                    child: const Text('Back to Login'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your email address and we will send you a link to reset your password.',
                  ),
                  const SizedBox(height: 32),
                  CkInput(
                    controller: _emailController,
                    label: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 32),
                  CkButton(
                    onPressed: _isLoading ? null : _submit,
                    fullWidth: true,
                    child: const Text('Send Reset Link'),
                  ),
                ],
              ),
      ),
    );
  }
}
