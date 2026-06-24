import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import '../../../core/config.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _customUrlController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _errorMessage;
  bool _showCustomServer = false;
  bool _pingLoading = false;
  String? _pingError;
  bool _serverConnected = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _testAndConnect() async {
    final url = _customUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _pingError = 'Please enter a server URL.');
      return;
    }
    setState(() { _pingLoading = true; _pingError = null; _serverConnected = false; });
    try {
      final uri = Uri.parse('$url/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await AppConfig.setCustomUrl(url);
        ref.read(baseUrlProvider.notifier).state = url;
        setState(() {
          _pingLoading = false;
          _showCustomServer = false;
          _serverConnected = true;
          _pingError = null;
        });
      } else {
        setState(() {
          _pingLoading = false;
          _pingError = 'Server returned status ${response.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        _pingLoading = false;
        _pingError = 'Could not reach server: ${e.toString()}';
      });
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final token = await ref.read(authRepositoryProvider).login(email, password);
      ref.read(authProvider.notifier).setToken(token);
      await SecureStorage.setRememberMe(_rememberMe);
      if (_rememberMe) {
        await SecureStorage.saveAccessToken(token);
      } else {
        await SecureStorage.clearTokens();
      }
      if (!mounted) return;
      context.go('/');
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
              'Welcome back',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: context.appHeading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to your Cookest account',
              style: GoogleFonts.inter(fontSize: 16, color: context.appMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_errorMessage != null) ...[
              CkAlert(
                variant: CkAlertVariant.error,
                title: 'Sign in failed',
                dismissible: true,
                onDismiss: () => setState(() => _errorMessage = null),
                child: Text(_errorMessage!),
              ),
              const SizedBox(height: 16),
            ],
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
            const SizedBox(height: 8),
            if (_serverConnected) ...[
              CkAlert(
                variant: CkAlertVariant.success,
                title: 'Connected to custom server',
                dismissible: true,
                onDismiss: () => setState(() => _serverConnected = false),
                child: Text(AppConfig.baseUrl),
              ),
              const SizedBox(height: 8),
            ],
            if (!_serverConnected && AppConfig.baseUrl != AppConfig.devBaseUrl) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Using custom server: ${AppConfig.baseUrl}',
                  style: GoogleFonts.inter(fontSize: 12, color: context.appMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() {
                  _showCustomServer = !_showCustomServer;
                  if (!_showCustomServer) _pingError = null;
                }),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  _showCustomServer
                      ? 'Connect to a custom server ▴'
                      : 'Connect to a custom server ▾',
                  style: GoogleFonts.inter(fontSize: 13, color: context.appMuted),
                ),
              ),
            ),
            if (_showCustomServer) ...[
              const SizedBox(height: 8),
              CkInput(
                controller: _customUrlController,
                label: 'Server URL',
                placeholder: 'http://192.168.1.1:8080',
                keyboardType: TextInputType.url,
                fullWidth: true,
              ),
              const SizedBox(height: 8),
              if (_pingError != null) ...[
                CkAlert(
                  variant: CkAlertVariant.error,
                  title: 'Connection failed',
                  dismissible: true,
                  onDismiss: () => setState(() => _pingError = null),
                  child: Text(_pingError!),
                ),
                const SizedBox(height: 8),
              ],
              CkButton(
                onPressed: _pingLoading ? null : _testAndConnect,
                loading: _pingLoading,
                fullWidth: true,
                child: const Text('Test & Connect'),
              ),
              const SizedBox(height: 8),
            ],
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                children: [
                  CkCheckbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Remember me',
                    style: GoogleFonts.inter(color: context.appMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CkButton(
              onPressed: _submit,
              loading: _isLoading,
              fullWidth: true,
              size: CkButtonSize.lg,
              child: const Text('Sign in'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                CkButton(
                  variant: CkButtonVariant.ghost,
                  size: CkButtonSize.sm,
                  onPressed: () => context.push('/register'),
                  child: const Text('Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
