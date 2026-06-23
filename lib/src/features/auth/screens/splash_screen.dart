import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/push_notification_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.post('/api/auth/refresh');
      final token = response.data['access_token'];
      if (token != null) {
        ref.read(authProvider.notifier).setToken(token);
        ref.read(pushNotificationServiceProvider).initializeAndRegisterToken();
        if (mounted) context.go('/');
      } else {
        if (mounted) context.go('/login');
      }
    } catch (e) {
      final rememberMe = await SecureStorage.getRememberMe();
      if (rememberMe) {
        final storedToken = await SecureStorage.getAccessToken();
        if (storedToken != null && !JwtDecoder.isExpired(storedToken)) {
          ref.read(authProvider.notifier).setToken(storedToken);
          ref.read(pushNotificationServiceProvider).initializeAndRegisterToken();
          if (mounted) context.go('/');
          return;
        }
      }
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: CookestTokens.colorPrimaryDEFAULT,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.chefHat, size: 72, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Cookest',
              style: GoogleFonts.playfairDisplay(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cook smarter, eat better',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 64),
            const CkSpinner(color: CkSpinnerColor.white, size: CkSpinnerSize.lg),
          ],
        ),
      ),
    );
  }
}
