import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import 'package:cookest/src/features/pantry/repositories/inventory_repository.dart';
import '../repositories/recipe_repository.dart';
import '../models/recipe.dart';
import '../../profile/screens/manage_recipes_screen.dart';
import 'recipes_screen.dart';
import '../../auth/providers/auth_provider.dart';


final recipeDetailProvider = FutureProvider.family<Recipe, String>((ref, id) {
  return ref.watch(recipeRepositoryProvider).getRecipe(id);
});

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _isFavorite = false;
  bool _importing = false;

  Future<void> _importRecipe(BuildContext context, Recipe recipe) async {
    setState(() => _importing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await ref.read(recipeRepositoryProvider).importRecipe(recipe.id);
      ref.invalidate(communityRecipesProvider);
      ref.invalidate(myRecipesListProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${recipe.name} imported successfully!'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              final newId = res['id']?.toString();
              if (newId != null && context.mounted) {
                context.pushReplacement('/recipes/$newId');
              }
            },
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to import recipe: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  void _showCookSheet(BuildContext context, Recipe recipe) {
    if (recipe.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No step-by-step instructions available.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CookingModeSheet(recipe: recipe),
    );
  }

  /// Record that the user cooked this recipe. The backend deducts the
  /// recipe's ingredients from the pantry (FIFO/expiry-aware).
  Future<void> _markCooked(BuildContext context, Recipe recipe) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(inventoryRepositoryProvider)
          .cookRecipe(widget.recipeId, recipe.servings);
      ref.invalidate(inventoryListProvider);
      ref.invalidate(expiringCountProvider);
      ref.invalidate(recipeSuggestionsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Marked as cooked — pantry updated.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not mark cooked: $e')),
      );
    }
  }

  Widget _buildBottomBar(BuildContext context, Recipe recipe) {
    final hasSteps = recipe.steps.isNotEmpty;
    final currentUserId = ref.watch(authProvider).userId;
    final isCommunityRecipe = recipe.authorId != null && recipe.authorId != currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(
          top: BorderSide(color: context.appBorder, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          // Mark Cooked icon button
          Tooltip(
            message: 'Mark as cooked',
            child: Material(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _markCooked(context, recipe),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.appBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.check,
                    size: 20,
                    color: context.appMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Import button for community recipes
          if (isCommunityRecipe) ...[
            Expanded(
              child: CkButton(
                size: CkButtonSize.lg,
                variant: CkButtonVariant.secondary,
                loading: _importing,
                iconLeft: const Icon(LucideIcons.download, size: 18),
                onPressed: () => _importRecipe(context, recipe),
                child: const Text('Import Recipe'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Cook Now primary CTA
          Expanded(
            child: CkButton(
              fullWidth: true,
              size: CkButtonSize.lg,
              iconLeft: const Icon(LucideIcons.chefHat, size: 18),
              onPressed: hasSteps
                  ? () => _showCookSheet(context, recipe)
                  : null,
              child: Text(
                hasSteps ? 'Cook Now' : 'No Instructions',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));
    final recipeVal = recipeAsync.valueOrNull;

    return Scaffold(
      backgroundColor: context.appBackground,
      bottomNavigationBar: recipeVal != null ? _buildBottomBar(context, recipeVal) : null,
      body: recipeAsync.when(
        loading: () => const Center(child: CkSpinner()),
        error: (e, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackButton(onPressed: () => context.pop()),
                const SizedBox(height: 16),
                CkAlert(
                  variant: CkAlertVariant.error,
                  child: Text('Failed to load recipe: $e'),
                ),
              ],
            ),
          ),
        ),
        data: (recipe) {
          final heroUrl = recipe.bestImageUrl;
          return CustomScrollView(
            slivers: [
              // ── Hero image app bar ─────────────────────────────────────
              SliverAppBar(
                backgroundColor: heroUrl != null
                    ? Colors.transparent
                    : context.appBackground,
                expandedHeight: heroUrl != null ? 280 : kToolbarHeight,
                pinned: true,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft,
                        color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isFavorite
                            ? LucideIcons.heart
                            : LucideIcons.heart,
                        color: _isFavorite
                            ? CookestTokens.colorStatusError
                            : Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _isFavorite = !_isFavorite),
                    ),
                  ),
                ],
                flexibleSpace: heroUrl != null
                    ? FlexibleSpaceBar(
                        titlePadding: EdgeInsets.zero,
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: heroUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: context.appSurface,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) =>
                                  Container(
                                color: context.appSurface,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.utensils,
                                        size: 48,
                                        color: context.appMuted),
                                    const SizedBox(height: 8),
                                    Text('Image unavailable',
                                        style: TextStyle(
                                            color: context.appMuted,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                            // Gradient overlay for readability
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.0, 0.5, 1.0],
                                  colors: [
                                    Colors.black38,
                                    Colors.transparent,
                                    Colors.black54,
                                  ],
                                ),
                              ),
                            ),
                            // Recipe title at bottom of image
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Text(
                                recipe.name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    const Shadow(
                                      blurRadius: 8,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FlexibleSpaceBar(
                        title: Text(
                          recipe.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.appHeading,
                          ),
                        ),
                        titlePadding: const EdgeInsets.only(
                            left: 60, bottom: 16, right: 60),
                      ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Dietary/Category badges ────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (recipe.category != null)
                            CkBadge(
                              variant: CkBadgeVariant.info,
                              size: CkBadgeSize.md,
                              child: Text(recipe.category!),
                            ),
                          if (recipe.cuisine != null)
                            CkBadge(
                              variant: CkBadgeVariant.standard,
                              size: CkBadgeSize.md,
                              child: Text(recipe.cuisine!),
                            ),
                          if (recipe.isVegetarian)
                            const CkBadge(
                              variant: CkBadgeVariant.success,
                              size: CkBadgeSize.sm,
                              child: Text('Vegetarian'),
                            ),
                          if (recipe.isVegan)
                            const CkBadge(
                              variant: CkBadgeVariant.success,
                              size: CkBadgeSize.sm,
                              child: Text('Vegan'),
                            ),
                          if (recipe.isGlutenFree)
                            const CkBadge(
                              variant: CkBadgeVariant.warning,
                              size: CkBadgeSize.sm,
                              child: Text('Gluten-Free'),
                            ),
                          if (recipe.isDairyFree)
                            const CkBadge(
                              variant: CkBadgeVariant.warning,
                              size: CkBadgeSize.sm,
                              child: Text('Dairy-Free'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // ── Quick stats row ────────────────────────────────
                      Row(
                        children: [
                          if (recipe.totalTimeMin != null) ...[
                            Icon(LucideIcons.clock,
                                size: 14, color: context.appMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.totalTimeMin} min',
                              style: TextStyle(
                                  color: context.appMuted, fontSize: 13),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Icon(LucideIcons.users,
                              size: 14, color: context.appMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.servings} servings',
                            style: TextStyle(
                                color: context.appMuted, fontSize: 13),
                          ),
                          if (recipe.difficulty != null) ...[
                            const SizedBox(width: 16),
                            Icon(LucideIcons.barChart2,
                                size: 14, color: context.appMuted),
                            const SizedBox(width: 4),
                            Text(
                              recipe.difficulty!,
                              style: TextStyle(
                                  color: context.appMuted, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                      if (recipe.description != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          recipe.description!,
                          style:
                              TextStyle(color: context.appMuted, fontSize: 14),
                        ),
                      ],
                      if (recipe.nutrition != null) ...[
                        const SizedBox(height: 20),
                        _NutritionCard(nutrition: recipe.nutrition!),
                      ],
                      const SizedBox(height: 20),
                      // ── Ingredients ────────────────────────────────────
                      Text(
                        'Ingredients',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: context.appHeading,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      CkCard(
                        variant: CkCardVariant.standard,
                        padding: CkCardPadding.md,
                        child: recipe.ingredients.isEmpty
                            ? Text(
                                'No ingredient data available.',
                                style: TextStyle(
                                    color: context.appMuted, fontSize: 14),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: recipe.ingredients
                                    .map(
                                      (ing) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('• ',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Expanded(
                                              child: Text(
                                                ing.display,
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // ── Instructions ───────────────────────────────────
                      Text(
                        'Instructions',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: context.appHeading,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      if (recipe.steps.isEmpty)
                        CkCard(
                          variant: CkCardVariant.standard,
                          padding: CkCardPadding.md,
                          child: Text(
                            'No step-by-step instructions available.',
                            style: TextStyle(
                                color: context.appMuted, fontSize: 14),
                          ),
                        )
                      else
                        ...recipe.steps.map(
                          (step) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: CookestTokens.colorPrimaryDEFAULT,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${step.stepNumber}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(step.instruction,
                                          style:
                                              const TextStyle(fontSize: 14)),
                                      if (step.durationMin != null) ...[
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          Icon(LucideIcons.clock,
                                              size: 12,
                                              color: context.appMuted),
                                          const SizedBox(width: 4),
                                          Text('${step.durationMin} min',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.appMuted)),
                                        ]),
                                      ],
                                      if (step.tip != null) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: CookestTokens
                                                .colorPrimaryDEFAULT
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(LucideIcons.lightbulb,
                                                  size: 13,
                                                  color: CookestTokens
                                                      .colorPrimaryDEFAULT),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  step.tip!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: CookestTokens
                                                        .colorPrimaryDEFAULT,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Extra bottom padding to clear the sticky bar
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final RecipeNutrition nutrition;
  const _NutritionCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return CkCard(
      variant: CkCardVariant.standard,
      padding: CkCardPadding.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition${nutrition.perServing ? ' (per serving)' : ''}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.appHeading,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NutritionPill(
                label: 'Calories',
                value: nutrition.calories?.toStringAsFixed(0),
                unit: 'kcal',
                color: CookestTokens.colorStatusError,
              ),
              _NutritionPill(
                label: 'Protein',
                value: nutrition.proteinG?.toStringAsFixed(1),
                unit: 'g',
                color: CookestTokens.colorPrimaryDEFAULT,
              ),
              _NutritionPill(
                label: 'Carbs',
                value: nutrition.carbsG?.toStringAsFixed(1),
                unit: 'g',
                color: CookestTokens.colorStatusWarning,
              ),
              _NutritionPill(
                label: 'Fat',
                value: nutrition.fatG?.toStringAsFixed(1),
                unit: 'g',
                color: CookestTokens.colorStatusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionPill extends StatelessWidget {
  final String label;
  final String? value;
  final String unit;
  final Color color;

  const _NutritionPill({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value != null ? '$value $unit' : '—',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: context.appMuted)),
      ],
    );
  }
}

class _CookingModeSheet extends StatefulWidget {
  final Recipe recipe;
  const _CookingModeSheet({required this.recipe});

  @override
  State<_CookingModeSheet> createState() => _CookingModeSheetState();
}

class _CookingModeSheetState extends State<_CookingModeSheet> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps;
    final step = steps[_currentStep];
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == steps.length - 1;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Step ${step.stepNumber} of ${steps.length}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.appHeading,
                  ),
                ),
                const Spacer(),
                if (step.durationMin != null)
                  Row(children: [
                    Icon(LucideIcons.clock,
                        size: 14, color: context.appMuted),
                    const SizedBox(width: 4),
                    Text('${step.durationMin} min',
                        style: TextStyle(
                            color: context.appMuted, fontSize: 13)),
                  ]),
              ],
            ),
          ),
          if (step.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: step.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.instruction,
                      style:
                          const TextStyle(fontSize: 16, height: 1.6)),
                  if (step.tip != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CookestTokens.colorPrimaryDEFAULT
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.lightbulb,
                              size: 16,
                              color: CookestTokens.colorPrimaryDEFAULT),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.tip!,
                              style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      CookestTokens.colorPrimaryDEFAULT),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(steps.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentStep ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentStep
                      ? CookestTokens.colorPrimaryDEFAULT
                      : context.appBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                if (!isFirst) ...[
                  Expanded(
                    child: CkButton(
                      variant: CkButtonVariant.secondary,
                      iconLeft:
                          const Icon(LucideIcons.arrowLeft, size: 16),
                      onPressed: () =>
                          setState(() => _currentStep--),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: isLast
                      ? CkButton(
                          iconLeft:
                              const Icon(LucideIcons.check, size: 16),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done!'),
                        )
                      : CkButton(
                          iconRight:
                              const Icon(LucideIcons.arrowRight, size: 16),
                          onPressed: () =>
                              setState(() => _currentStep++),
                          child: const Text('Next Step'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
