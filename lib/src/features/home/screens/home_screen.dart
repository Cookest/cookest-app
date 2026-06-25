import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../pantry/repositories/inventory_repository.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../inbox/repositories/notification_repository.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlanAsync = ref.watch(currentMealPlanProvider);
    final expiringCountAsync = ref.watch(expiringCountProvider);
    final profileAsync = ref.watch(profileProvider);

    final firstName = profileAsync.maybeWhen(
      data: (p) => p.name.split(' ').first,
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: Text(
          firstName.isNotEmpty
              ? '${_greeting()}, $firstName 👋'
              : '${_greeting()} 👋',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.appHeading,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadAsync = ref.watch(unreadCountProvider);
              final count = unreadAsync.valueOrNull ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bell),
                    onPressed: () => context.push('/inbox'),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.messageCircle),
            onPressed: () => context.push('/chat'),
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: CkAvatar(alt: 'User', size: CkAvatarSize.sm),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pantry alert
            expiringCountAsync.maybeWhen(
              data: (count) => count > 0
                  ? Column(
                      children: [
                        CkAlert(
                          variant: CkAlertVariant.warning,
                          title: 'Pantry alert',
                          dismissible: false,
                          icon: const Icon(LucideIcons.alertTriangle, size: 16),
                          child: GestureDetector(
                            onTap: () => context.push('/pantry'),
                            child: Text('$count item(s) expiring soon — tap to view'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),

            // Today's meals
            Text(
              "Today's meals",
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.appHeading,
              ),
            ),
            const SizedBox(height: 12),
            mealPlanAsync.when(
              loading: () => const CkSkeletonCard(),
              error: (e, st) => CkCard(
                variant: CkCardVariant.standard,
                padding: CkCardPadding.md,
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 16, color: context.appMuted),
                    const SizedBox(width: 8),
                    Text('No meal plan this week',
                        style: TextStyle(color: context.appMuted)),
                    const Spacer(),
                    CkButton(
                      variant: CkButtonVariant.ghost,
                      size: CkButtonSize.sm,
                      onPressed: () => context.push('/meals'),
                      child: const Text('Plan'),
                    ),
                  ],
                ),
              ),
              data: (mealPlan) {
                if (mealPlan == null) {
                  return CkCard(
                    variant: CkCardVariant.interactive,
                    padding: CkCardPadding.md,
                    onTap: () => context.push('/meals'),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendarPlus,
                            size: 18, color: context.appMuted),
                        const SizedBox(width: 10),
                        Text('Set up this week\'s meal plan',
                            style: TextStyle(color: context.appMuted)),
                        const Spacer(),
                        const Icon(LucideIcons.chevronRight, size: 16),
                      ],
                    ),
                  );
                }
                final dayOfWeek = DateTime.now().weekday - 1;
                final slots = mealPlan.slots
                    .where((s) => s.dayOfWeek == dayOfWeek)
                    .toList();
                return Column(
                  children: ['breakfast', 'lunch', 'dinner'].map((mealType) {
                    final slot = slots
                        .where((s) => s.mealType == mealType)
                        .firstOrNull;
                    final recipe = slot?.recipe;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MealSlotCard(
                        mealType: mealType,
                        recipeName: recipe?.name,
                        totalTimeMin: recipe?.totalTimeMin,
                        onTap: recipe != null
                            ? () => context.push('/recipes/${recipe.id}')
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick actions
            Row(
              children: [
                Text(
                  'Quick actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.appHeading,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/meals'),
                  child: const Text('Full plan'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickActionCard(
                  icon: LucideIcons.search,
                  label: 'Find Recipe',
                  onTap: () => context.push('/recipes'),
                ),
                const SizedBox(width: 8),
                _QuickActionCard(
                  icon: LucideIcons.calendar,
                  label: 'Meal Plan',
                  onTap: () => context.push('/meals'),
                ),
                const SizedBox(width: 8),
                _QuickActionCard(
                  icon: LucideIcons.shoppingCart,
                  label: 'Groceries',
                  onTap: () => context.push('/groceries'),
                ),
                const SizedBox(width: 8),
                _QuickActionCard(
                  icon: LucideIcons.messageCircle,
                  label: 'AI Chat',
                  onTap: () => context.push('/chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meal slot card ───────────────────────────────────────────────────────────

class _MealSlotCard extends StatelessWidget {
  final String mealType;
  final String? recipeName;
  final int? totalTimeMin;
  final VoidCallback? onTap;

  const _MealSlotCard({
    required this.mealType,
    this.recipeName,
    this.totalTimeMin,
    this.onTap,
  });

  static const _icons = {
    'breakfast': LucideIcons.sun,
    'lunch': LucideIcons.salad,
    'dinner': LucideIcons.moon,
  };

  static const _labels = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[mealType] ?? LucideIcons.utensils;
    final label = _labels[mealType] ?? mealType;

    return CkCard(
      variant: recipeName != null
          ? CkCardVariant.interactive
          : CkCardVariant.standard,
      padding: CkCardPadding.md,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.appMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: context.appMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: recipeName != null
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipeName!,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (totalTimeMin != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$totalTimeMin min',
                          style: TextStyle(
                              fontSize: 12, color: context.appMuted),
                        ),
                      ],
                    ],
                  )
                : Text(
                    'Not planned',
                    style: TextStyle(
                        color: context.appMuted,
                        fontSize: 13,
                        fontStyle: FontStyle.italic),
                  ),
          ),
          if (recipeName != null)
            const Icon(LucideIcons.chevronRight, size: 14),
        ],
      ),
    );
  }
}

// ── Quick action card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CkCard(
        variant: CkCardVariant.interactive,
        padding: CkCardPadding.sm,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
