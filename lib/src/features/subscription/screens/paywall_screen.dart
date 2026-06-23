import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../../../core/api/api_client.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  String? _loadingTier;

  Future<void> _checkout(String tier) async {
    setState(() {
      _isLoading = true;
      _loadingTier = tier;
    });
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final response = await ref.read(dioProvider).post(
        '/api/subscription/checkout',
        data: {'tier': tier},
      );
      final url = response.data['url'] as String;
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Redirecting to Stripe checkout: $url')),
      );
      router.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.response?.data['error'] ?? e.message}')),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; _loadingTier = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                LucideIcons.crown,
                size: 64,
                color: CookestTokens.colorPrimaryDEFAULT,
              ),
              const SizedBox(height: 20),
              Text(
                'Unlock Cookest Pro',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.appHeading,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Unlimited AI chat, price comparison, recipe creation, and more.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: context.appMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ..._features.map(_buildFeatureRow),
              const SizedBox(height: 32),
              _TierCard(
                title: 'Pro',
                price: '€9.99',
                period: '/month',
                description: 'Perfect for individuals',
                isPopular: true,
                loading: _isLoading && _loadingTier == 'pro',
                onTap: _isLoading ? null : () => _checkout('pro'),
              ),
              const SizedBox(height: 16),
              _TierCard(
                title: 'Family',
                price: '€14.99',
                period: '/month',
                description: 'Share with up to 5 family members',
                isPopular: false,
                loading: _isLoading && _loadingTier == 'family',
                onTap: _isLoading ? null : () => _checkout('family'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static const _features = [
    'Unlimited AI Chat',
    'Shopping List Price Optimizer',
    'Create & share custom recipes',
    'Advanced AI taste learning',
  ];

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(LucideIcons.checkCircle2, color: CookestTokens.colorStatusSuccess, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 15, color: context.appHeading),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String description;
  final bool isPopular;
  final bool loading;
  final VoidCallback? onTap;

  const _TierCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.isPopular,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CkCard(
      variant: isPopular ? CkCardVariant.interactive : CkCardVariant.outlined,
      padding: CkCardPadding.lg,
      onTap: loading ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular) ...[
            CkBadge(
              variant: CkBadgeVariant.success,
              child: const Text('MOST POPULAR'),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.appHeading,
                ),
              ),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: price,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.appHeading,
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.appMuted,
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 14, color: context.appMuted),
          ),
          const SizedBox(height: 16),
          CkButton(
            variant: isPopular ? CkButtonVariant.primary : CkButtonVariant.secondary,
            fullWidth: true,
            size: CkButtonSize.lg,
            loading: loading,
            onPressed: loading ? null : onTap,
            child: Text(isPopular ? 'Get Pro' : 'Get Family'),
          ),
        ],
      ),
    );
  }
}
