import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../repositories/profile_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/storage/secure_storage.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../pantry/repositories/inventory_repository.dart';
import '../../shopping_list/repositories/shopping_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {}
    await SecureStorage.clearAuthState();
    
    // Invalidate all cached user data to prevent data leakage between accounts
    ref.invalidate(profileProvider);
    ref.invalidate(subscriptionProvider);
    ref.invalidate(currentMealPlanProvider);
    ref.invalidate(inventoryListProvider);
    ref.invalidate(expiringCountProvider);
    ref.invalidate(shoppingListProvider);
    
    ref.read(authProvider.notifier).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.appHeading,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CkSpinner()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: CkAlert(
            variant: CkAlertVariant.error,
            child: Text('Failed to load profile: $e'),
          ),
        ),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            children: [
              Center(
                child: CkAvatar(
                  alt: profile.name,
                  size: CkAvatarSize.xl,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.appHeading,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (profile.name != profile.email)
                Center(
                  child: Text(
                    profile.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appMuted,
                        ),
                  ),
                ),
              if (profile.name == profile.email)
                const SizedBox(height: 8),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  CkBadge(
                    variant: profile.isEmailVerified
                        ? CkBadgeVariant.success
                        : CkBadgeVariant.warning,
                    child: Text(
                      profile.isEmailVerified
                          ? 'Email verified'
                          : 'Email not verified',
                    ),
                  ),
                  CkBadge(
                    variant: profile.twoFactorEnabled
                        ? CkBadgeVariant.success
                        : CkBadgeVariant.standard,
                    child: Text(
                      profile.twoFactorEnabled ? '2FA on' : '2FA off',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              subscriptionAsync.maybeWhen(
                data: (sub) {
                  final isPro = sub.tier == 'pro' || sub.tier == 'family';
                  return Center(
                    child: CkBadge(
                      variant: isPro
                          ? CkBadgeVariant.success
                          : CkBadgeVariant.standard,
                      child: Text(sub.tier.toUpperCase()),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              CkCard(
                padding: CkCardPadding.md,
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Household',
                        value: '${profile.householdSize}',
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Dietary tags',
                        value: '${profile.dietaryRestrictions.length}',
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Allergies',
                        value: '${profile.allergies.length}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CkCard(
                padding: CkCardPadding.md,
                child: Column(
                  children: [
                    _buildSettingsRow(
                      context,
                      icon: LucideIcons.user,
                      label: 'Account & Settings',
                      onTap: () => context.push('/settings'),
                    ),
                    const CkDivider(),
                    _buildSettingsRow(
                      context,
                      icon: LucideIcons.chefHat,
                      label: 'My Recipes',
                      onTap: () => context.go('/recipes'),
                    ),
                    const CkDivider(),
                    _buildSettingsRow(
                      context,
                      icon: LucideIcons.users,
                      label: 'Family',
                      onTap: () => context.push('/family'),
                    ),
                    const CkDivider(),
                    _buildSettingsRow(
                      context,
                      icon: LucideIcons.crown,
                      label: 'Upgrade',
                      onTap: () => context.push('/paywall'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CkButton(
                variant: CkButtonVariant.danger,
                fullWidth: true,
                onPressed: () => _logout(context, ref),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.appMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.appHeading,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: context.appMuted),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appHeading,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.appMuted,
              ),
        ),
      ],
    );
  }
}
