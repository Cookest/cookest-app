import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cookest_ui/cookest_ui.dart';

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(CookestSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 64, color: CookestColors.primary),
            const SizedBox(height: CookestSpacing.xl),
            Text(
              'Verify your email',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CookestSpacing.md),
            const Text(
              'We sent a verification link to your email address. Please click the link to verify your account.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CookestSpacing.xxl),
            CookestButton(
              onPressed: () => context.go('/login'),
              text: 'Back to Login',
            ),
          ],
        ),
      ),
    );
  }
}
