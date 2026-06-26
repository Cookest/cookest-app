import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../repositories/food_browse_repository.dart';
import '../models/food_recipe.dart';
import 'package:cookest/src/features/pantry/repositories/inventory_repository.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class FoodRecipeDetailScreen extends ConsumerWidget {
  final int recipeId;
  const FoodRecipeDetailScreen({super.key, required this.recipeId});

  void _showCookSheet(BuildContext context, FoodRecipeDetail recipe) {
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
      builder: (ctx) => _FoodCookingModeSheet(recipe: recipe),
    );
  }

  Future<void> _markCooked(BuildContext context, WidgetRef ref, FoodRecipeDetail recipe) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(inventoryRepositoryProvider)
          .cookRecipe(recipe.id.toString(), recipe.servings);
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

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, FoodRecipeDetail recipe) {
    final hasSteps = recipe.steps.isNotEmpty;

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
                onTap: () => _markCooked(context, ref, recipe),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(browseFoodDetailProvider(recipeId));
    final recipeVal = detailAsync.valueOrNull;

    return Scaffold(
      backgroundColor: context.appBackground,
      bottomNavigationBar: recipeVal != null ? _buildBottomBar(context, ref, recipeVal) : null,
      body: detailAsync.when(
        loading: () => const Center(child: CkSpinner()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CkAlert(
                variant: CkAlertVariant.error,
                child: Text('Failed to load recipe: $e'),
              ),
              const SizedBox(height: 16),
              CkButton(
                variant: CkButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
        data: (recipe) => _RecipeBody(recipe: recipe),
      ),
    );
  }
}

class _RecipeBody extends StatefulWidget {
  final FoodRecipeDetail recipe;
  const _RecipeBody({required this.recipe});

  @override
  State<_RecipeBody> createState() => _RecipeBodyState();
}

class _RecipeBodyState extends State<_RecipeBody> {

  @override
  Widget build(BuildContext context) {
    final heroImage = widget.recipe.imageUrls.isNotEmpty
        ? widget.recipe.imageUrls.first
        : null;

    return CustomScrollView(
      slivers: [
        // Hero image + back button
        SliverAppBar(
          expandedHeight: heroImage != null ? 260 : 80,
          pinned: true,
          backgroundColor: context.appBackground,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: heroImage != null
              ? FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: heroImage,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, url, err) =>
                            Container(color: context.appSurface),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black45],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.recipe.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.appHeading,
                  ),
                ),
                const SizedBox(height: 8),

                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (widget.recipe.category != null)
                      CkBadge(
                        variant: CkBadgeVariant.info,
                        size: CkBadgeSize.sm,
                        child: Text(widget.recipe.category!),
                      ),
                    if (widget.recipe.cuisine != null)
                      CkBadge(
                        variant: CkBadgeVariant.standard,
                        size: CkBadgeSize.sm,
                        child: Text(widget.recipe.cuisine!),
                      ),
                    if (widget.recipe.isVegetarian)
                      const CkBadge(
                        variant: CkBadgeVariant.success,
                        size: CkBadgeSize.sm,
                        child: Text('Vegetarian'),
                      ),
                    if (widget.recipe.isVegan)
                      const CkBadge(
                        variant: CkBadgeVariant.success,
                        size: CkBadgeSize.sm,
                        child: Text('Vegan'),
                      ),
                    if (widget.recipe.isGlutenFree)
                      const CkBadge(
                        variant: CkBadgeVariant.warning,
                        size: CkBadgeSize.sm,
                        child: Text('Gluten-Free'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Meta row
                Row(
                  children: [
                    if (widget.recipe.totalTimeMin != null) ...[
                      Icon(LucideIcons.clock, size: 14, color: context.appMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.recipe.totalTimeMin} min',
                        style: TextStyle(color: context.appMuted, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(LucideIcons.users, size: 14, color: context.appMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.recipe.servings} servings',
                      style: TextStyle(color: context.appMuted, fontSize: 13),
                    ),
                    if (widget.recipe.difficulty != null) ...[
                      const SizedBox(width: 16),
                      Icon(LucideIcons.barChart2, size: 14, color: context.appMuted),
                      const SizedBox(width: 4),
                      Text(
                        widget.recipe.difficulty!,
                        style: TextStyle(color: context.appMuted, fontSize: 13),
                      ),
                    ],
                  ],
                ),

                if (widget.recipe.description != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.recipe.description!,
                    style: TextStyle(color: context.appMuted, fontSize: 14),
                  ),
                ],

                // Nutrition card
                if (widget.recipe.nutrition != null) ...[
                  const SizedBox(height: 20),
                  _NutritionCard(nutrition: widget.recipe.nutrition!),
                ],

                // Ingredients
                const SizedBox(height: 20),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.appHeading,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                CkCard(
                  variant: CkCardVariant.standard,
                  padding: CkCardPadding.md,
                  child: widget.recipe.ingredients.isEmpty
                      ? Text('No ingredient data.',
                          style: TextStyle(color: context.appMuted))
                      : Column(
                          children: widget.recipe.ingredients
                              .map((ing) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ',
                                            style: TextStyle(fontSize: 14)),
                                        Expanded(
                                          child: Text(
                                            _ingredientLabel(ing),
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                ),

                // Steps
                if (widget.recipe.steps.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Instructions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.appHeading,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.recipe.steps.map(
                    (step) => _StepCard(
                      step: step,
                    ),
                  ),
                ],

                // Source attribution
                if (widget.recipe.sourceUrl != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(LucideIcons.link, size: 12, color: context.appMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Source: ${widget.recipe.sourceUrl}',
                          style: TextStyle(
                              color: context.appMuted,
                              fontSize: 11,
                              overflow: TextOverflow.ellipsis),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _ingredientLabel(FoodRecipeIngredient ing) {
    final parts = <String>[];
    if (ing.quantity != null) {
      final q = ing.quantity! % 1 == 0
          ? ing.quantity!.toInt().toString()
          : ing.quantity!.toString();
      parts.add(q);
    }
    if (ing.unit != null) parts.add(ing.unit!);
    parts.add(ing.name);
    if (ing.note != null) parts.add('(${ing.note})');
    return parts.join(' ');
  }
}

class _NutritionCard extends StatelessWidget {
  final FoodRecipeNutrition nutrition;
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
            'Nutrition per serving',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.appHeading,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (nutrition.caloriesKcal != null)
                _NutrientChip(
                  label: 'Calories',
                  value: '${nutrition.caloriesKcal!.round()} kcal',
                  color: CookestTokens.colorPrimaryDEFAULT,
                ),
              if (nutrition.proteinG != null)
                _NutrientChip(
                  label: 'Protein',
                  value: '${nutrition.proteinG!.toStringAsFixed(1)} g',
                  color: Colors.blue,
                ),
              if (nutrition.carbsG != null)
                _NutrientChip(
                  label: 'Carbs',
                  value: '${nutrition.carbsG!.toStringAsFixed(1)} g',
                  color: Colors.orange,
                ),
              if (nutrition.fatG != null)
                _NutrientChip(
                  label: 'Fat',
                  value: '${nutrition.fatG!.toStringAsFixed(1)} g',
                  color: Colors.purple,
                ),
              if (nutrition.fiberG != null)
                _NutrientChip(
                  label: 'Fiber',
                  value: '${nutrition.fiberG!.toStringAsFixed(1)} g',
                  color: Colors.teal,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NutrientChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: TextStyle(color: context.appMuted, fontSize: 11)),
      ],
    );
  }
}



// ── Step Card ─────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final FoodRecipeStep step;

  const _StepCard({
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrl = step.imageUrl;
    final showImageArea = displayUrl != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CkCard(
        variant: CkCardVariant.standard,
        padding: CkCardPadding.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ──────────────────────────────────────────────────
            if (showImageArea)
              ClipRRect(
                key: ValueKey(displayUrl),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: displayUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, err) =>
                        Container(color: context.appSurface),
                  ),
                ),
              ),

            // ── Step body ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12, top: 1),
                    decoration: BoxDecoration(
                      color: CookestTokens.colorPrimaryDEFAULT,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${step.stepNumber}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.instruction,
                            style: const TextStyle(fontSize: 14)),
                        if (step.durationMin != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(LucideIcons.clock,
                                  size: 11, color: context.appMuted),
                              const SizedBox(width: 3),
                              Text('${step.durationMin} min',
                                  style: TextStyle(
                                      fontSize: 11, color: context.appMuted)),
                            ],
                          ),
                        ],
                        if (step.tip != null) ...[
                          const SizedBox(height: 4),
                          Text('💡 ${step.tip}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.appMuted,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodCookingModeSheet extends StatefulWidget {
  final FoodRecipeDetail recipe;
  const _FoodCookingModeSheet({required this.recipe});

  @override
  State<_FoodCookingModeSheet> createState() => _FoodCookingModeSheetState();
}

class _FoodCookingModeSheetState extends State<_FoodCookingModeSheet> {
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

