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

// ── Image generation state ────────────────────────────────────────────────────

enum _GenState { idle, queued, polling, done }

class _ImageGenNotifier extends StateNotifier<Map<int, String?>> {
  /// stepIndex → imageUrl (null while pending)
  _ImageGenNotifier() : super({});

  void setJobMap(Map<int, String?> initial) => state = initial;

  void setImageUrl(int stepIndex, String url) {
    state = {...state, stepIndex: url};
  }
}

final _imageGenProvider =
    StateNotifierProvider.autoDispose<_ImageGenNotifier, Map<int, String?>>(
  (ref) => _ImageGenNotifier(),
);

final _genStateProvider = StateProvider.autoDispose<_GenState>(
  (ref) => _GenState.idle,
);

// ── Screen ────────────────────────────────────────────────────────────────────

class FoodRecipeDetailScreen extends ConsumerWidget {
  final int recipeId;
  const FoodRecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(browseFoodDetailProvider(recipeId));

    return Scaffold(
      backgroundColor: context.appBackground,
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

class _RecipeBody extends ConsumerStatefulWidget {
  final FoodRecipeDetail recipe;
  const _RecipeBody({required this.recipe});

  @override
  ConsumerState<_RecipeBody> createState() => _RecipeBodyState();
}

class _RecipeBodyState extends ConsumerState<_RecipeBody> {
  Timer? _pollTimer;
  // jobId → stepIndex for pending jobs
  Map<String, int> _pendingJobs = {};

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    final repo = ref.read(foodBrowseRepositoryProvider);
    ref.read(_genStateProvider.notifier).state = _GenState.queued;

    try {
      final jobMap = await repo.generateStepImages(widget.recipe);
      // jobMap: stepIndex → jobId
      _pendingJobs = {for (final e in jobMap.entries) e.value: e.key};

      // Seed notifier with nulls (generating) for all steps
      ref
          .read(_imageGenProvider.notifier)
          .setJobMap({for (final idx in jobMap.keys) idx: null});

      ref.read(_genStateProvider.notifier).state = _GenState.polling;
      _startPolling(repo);
    } catch (e) {
      ref.read(_genStateProvider.notifier).state = _GenState.idle;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image generation failed: $e')),
        );
      }
    }
  }

  void _startPolling(FoodBrowseRepository repo) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (_pendingJobs.isEmpty) {
        _pollTimer?.cancel();
        ref.read(_genStateProvider.notifier).state = _GenState.done;
        return;
      }
      final toCheck = Map<String, int>.from(_pendingJobs);
      for (final entry in toCheck.entries) {
        try {
          final result = await repo.pollJob(entry.key);
          if (result.isDone && result.imageUrl != null) {
            ref
                .read(_imageGenProvider.notifier)
                .setImageUrl(entry.value, result.imageUrl!);
            _pendingJobs.remove(entry.key);
          } else if (result.isFailed) {
            _pendingJobs.remove(entry.key);
          }
        } catch (_) {
          // Network hiccup — retry next tick
        }
      }
      if (_pendingJobs.isEmpty && mounted) {
        _pollTimer?.cancel();
        ref.read(_genStateProvider.notifier).state = _GenState.done;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final heroImage = widget.recipe.imageUrls.isNotEmpty
        ? widget.recipe.imageUrls.first
        : null;
    final genState = ref.watch(_genStateProvider);
    final stepImages = ref.watch(_imageGenProvider);
    final isGenerating = genState == _GenState.queued || genState == _GenState.polling;

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
                  // Header row with AI generate button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Instructions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: context.appHeading,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (genState == _GenState.idle)
                        _AiGenerateButton(onPressed: _startGeneration),
                      if (isGenerating)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CookestTokens.colorPrimaryDEFAULT,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Generating…',
                              style: TextStyle(
                                  fontSize: 12, color: context.appMuted),
                            ),
                          ],
                        ),
                      if (genState == _GenState.done)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.checkCircle,
                                size: 14,
                                color: CookestTokens.colorPrimaryDEFAULT),
                            const SizedBox(width: 4),
                            Text(
                              'AI images ready',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: CookestTokens.colorPrimaryDEFAULT),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...widget.recipe.steps.map(
                    (step) => _StepCard(
                      step: step,
                      imageUrl: stepImages[step.stepNumber - 1],
                      isGenerating: isGenerating,
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

// ── AI Generate Button ────────────────────────────────────────────────────────

class _AiGenerateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AiGenerateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 13,
              color: CookestTokens.colorPrimaryDEFAULT,
            ),
            const SizedBox(width: 5),
            Text(
              'Gerar imagens',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CookestTokens.colorPrimaryDEFAULT,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step Card ─────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final FoodRecipeStep step;
  final String? imageUrl;
  final bool isGenerating;

  const _StepCard({
    required this.step,
    this.imageUrl,
    this.isGenerating = false,
  });

  @override
  Widget build(BuildContext context) {
    // If a real image came back from the step data, use it
    final displayUrl = imageUrl ?? step.imageUrl;
    final showImageArea = isGenerating || displayUrl != null;

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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: displayUrl != null
                    ? ClipRRect(
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
                      )
                    : _StepImageSkeleton(key: const ValueKey('skeleton')),
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

// ── Skeleton shimmer while image is generating ────────────────────────────────

class _StepImageSkeleton extends StatefulWidget {
  const _StepImageSkeleton({super.key});

  @override
  State<_StepImageSkeleton> createState() => _StepImageSkeletonState();
}

class _StepImageSkeletonState extends State<_StepImageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (ctx, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    context.appSurface,
                    Color.lerp(
                      context.appSurface,
                      context.appSurface.withValues(alpha: 0.4),
                      _anim.value,
                    )!,
                    context.appSurface,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 22,
                      color: CookestTokens.colorPrimaryDEFAULT
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A gerar imagem AI…',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
