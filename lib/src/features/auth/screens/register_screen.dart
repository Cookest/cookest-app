import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _password = '';
  String _confirmPassword = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() => _password = _passwordController.text));
    _confirmPasswordController.addListener(() => setState(() => _confirmPassword = _confirmPasswordController.text));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _hasMinLength() => _password.length >= 8;
  bool _hasUppercase() => _password.contains(RegExp(r'[A-Z]'));
  bool _hasLowercase() => _password.contains(RegExp(r'[a-z]'));
  bool _hasNumber() => _password.contains(RegExp(r'[0-9]'));
  bool _hasSpecialChar() => _password.contains(RegExp(r'[!@#$%^&*()\-_=\[\]{};:"<>,.?/|`~]'));
  bool _passwordsMatch() => _password == _confirmPassword && _password.isNotEmpty;

  Widget _requirementItem(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            met ? LucideIcons.check : LucideIcons.x,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: met ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Name is required.');
      return;
    }
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password is required.');
      return;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Password confirmation is required.');
      return;
    }

    // Check all password requirements
    if (!_hasMinLength()) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long.');
      return;
    }
    if (!_hasUppercase()) {
      setState(() => _errorMessage = 'Password must contain an uppercase letter.');
      return;
    }
    if (!_hasLowercase()) {
      setState(() => _errorMessage = 'Password must contain a lowercase letter.');
      return;
    }
    if (!_hasNumber()) {
      setState(() => _errorMessage = 'Password must contain a number.');
      return;
    }
    if (!_hasSpecialChar()) {
      setState(() => _errorMessage = 'Password must contain a special character (!@#\$%^&* etc).');
      return;
    }
    if (!_passwordsMatch()) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authRepositoryProvider).register(email, password, name);
      final token = await ref.read(authRepositoryProvider).login(email, password);
      ref.read(authProvider.notifier).setToken(token);
      await SecureStorage.setRememberMe(true);
      await SecureStorage.saveAccessToken(token);
      if (mounted) context.go('/onboarding');
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appSurface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(LucideIcons.chefHat, size: 48, color: CookestTokens.colorPrimaryDEFAULT),
            const SizedBox(height: 16),
            Text(
              'Create account',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: context.appHeading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Join thousands of home cooks',
              style: GoogleFonts.inter(fontSize: 16, color: context.appMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_errorMessage != null) ...[
              CkAlert(
                variant: CkAlertVariant.error,
                title: 'Registration failed',
                dismissible: true,
                onDismiss: () => setState(() => _errorMessage = null),
                child: Text(_errorMessage!),
              ),
              const SizedBox(height: 16),
            ],
            CkInput(
              controller: _nameController,
              label: 'Name',
              placeholder: 'Your full name',
              iconLeft: const Icon(LucideIcons.user, size: 16),
              fullWidth: true,
            ),
            const SizedBox(height: 16),
            CkInput(
              controller: _emailController,
              label: 'Email',
              placeholder: 'you@example.com',
              iconLeft: const Icon(LucideIcons.mail, size: 16),
              keyboardType: TextInputType.emailAddress,
              fullWidth: true,
            ),
            const SizedBox(height: 16),
            CkInput(
              controller: _passwordController,
              label: 'Password',
              placeholder: '••••••••',
              iconLeft: const Icon(LucideIcons.lock, size: 16),
              obscureText: true,
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password requirements:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.appMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _requirementItem('At least 8 characters', _hasMinLength()),
                  _requirementItem('Contains uppercase letter (A-Z)', _hasUppercase()),
                  _requirementItem('Contains lowercase letter (a-z)', _hasLowercase()),
                  _requirementItem('Contains number (0-9)', _hasNumber()),
                  _requirementItem('Contains special character (!@#\$%^&* etc)', _hasSpecialChar()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CkInput(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              placeholder: '••••••••',
              iconLeft: const Icon(LucideIcons.lock, size: 16),
              obscureText: true,
              fullWidth: true,
            ),
            if (_confirmPassword.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _requirementItem('Passwords match', _passwordsMatch()),
              ),
            ],
            const SizedBox(height: 24),
            CkButton(
              onPressed: _submit,
              loading: _isLoading,
              fullWidth: true,
              size: CkButtonSize.lg,
              child: const Text('Create account'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? '),
                CkButton(
                  variant: CkButtonVariant.ghost,
                  size: CkButtonSize.sm,
                  onPressed: () => context.pop(),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
