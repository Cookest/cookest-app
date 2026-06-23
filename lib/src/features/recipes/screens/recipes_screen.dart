import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../repositories/recipe_repository.dart';
import '../repositories/food_browse_repository.dart';
import '../models/recipe.dart';
import '../models/food_recipe.dart';
import 'generate_recipe_screen.dart';

final recipeSearchProvider = StateProvider<String>((ref) => '');
final recipeMatchInventoryProvider = StateProvider<bool>((ref) => false);
final recipeCategoryProvider = StateProvider<String>((ref) => 'All');

final recipesListProvider = FutureProvider<List<Recipe>>((ref) {
  final query = ref.watch(recipeSearchProvider);
  final matchInventory = ref.watch(recipeMatchInventoryProvider);
  final category = ref.watch(recipeCategoryProvider);
  return ref.watch(recipeRepositoryProvider).getRecipes(
    q: query.isEmpty ? null : query,
    matchInventory: matchInventory,
    category: category == 'All' ? null : category,
  );
});

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  static const _categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack'];
  String _activeTab = 'my';
  Timer? _debounce;
  Timer? _browseDebounce;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _browseDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(recipeSearchProvider.notifier).state = value;
    });
  }

  void _onBrowseSearchChanged(String value) {
    _browseDebounce?.cancel();
    _browseDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(browseSearchProvider.notifier).state = value;
      ref.read(browsePageProvider.notifier).state = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: Text(
          'Recipes',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.appHeading,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CkButton(
              variant: CkButtonVariant.ghost,
              size: CkButtonSize.sm,
              iconLeft: const Icon(LucideIcons.sparkles, size: 14),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const GenerateRecipeScreen(),
                ),
              ),
              child: const Text('IA'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CkButton(
              variant: CkButtonVariant.ghost,
              size: CkButtonSize.sm,
              iconLeft: const Icon(LucideIcons.plus, size: 16),
              onPressed: () => context.push('/recipes/create'),
              child: const Text('Add'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: CkTabs(
              variant: CkTabsVariant.underline,
              fullWidth: true,
              onChanged: (id) => setState(() => _activeTab = id),
              items: const [
                CkTabItem(id: 'my', label: 'My Recipes'),
                CkTabItem(id: 'browse', label: 'Browse'),
              ],
            ),
          ),
          Expanded(
            child: _activeTab == 'my'
                ? _MyRecipesTab(
                    categories: _categories,
                    onSearchChanged: _onSearchChanged,
                    onShowFilter: () => _showPantryFilterModal(context, ref),
                  )
                : _BrowseTab(onSearchChanged: _onBrowseSearchChanged),
          ),
        ],
      ),
    );
  }

  void _showPantryFilterModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Recipes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Only show recipes I can make',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  CkToggle(
                    value: ref.watch(recipeMatchInventoryProvider),
                    onChanged: (val) {
                      ref.read(recipeMatchInventoryProvider.notifier).state = val;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Shows only recipes where you have most ingredients in pantry',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.appMuted),
              ),
              const SizedBox(height: 16),
              CkButton(
                variant: CkButtonVariant.ghost,
                fullWidth: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── My Recipes Tab ──────────────────────────────────────────────────────────

class _MyRecipesTab extends ConsumerWidget {
  final List<String> categories;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onShowFilter;

  const _MyRecipesTab({
    required this.categories,
    required this.onSearchChanged,
    required this.onShowFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesListProvider);
    final selectedCategory = ref.watch(recipeCategoryProvider);
    final matchInventory = ref.watch(recipeMatchInventoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CkInput(
                  placeholder: 'Search recipes...',
                  iconLeft: const Icon(LucideIcons.search, size: 16),
                  fullWidth: true,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              CkButton(
                variant: matchInventory
                    ? CkButtonVariant.primary
                    : CkButtonVariant.secondary,
                size: CkButtonSize.sm,
                onPressed: onShowFilter,
                child: Icon(
                  LucideIcons.filter,
                  size: 18,
                  color: matchInventory
                      ? Colors.white
                      : context.appMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(recipeCategoryProvider.notifier).state = cat;
                    },
                    child: CkBadge(
                      variant: isSelected
                          ? CkBadgeVariant.success
                          : CkBadgeVariant.standard,
                      size: CkBadgeSize.md,
                      child: Text(cat),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (matchInventory) ...[
            const SizedBox(height: 8),
            CkBadge(
              variant: CkBadgeVariant.success,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.checkCircle, size: 14),
                  const SizedBox(width: 6),
                  const Text('Showing pantry matches'),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      ref.read(recipeMatchInventoryProvider.notifier).state = false;
                    },
                    child: const Icon(LucideIcons.x, size: 14),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: recipesAsync.when(
              loading: () => ListView(
                children: const [
                  CkSkeletonCard(),
                  SizedBox(height: 12),
                  CkSkeletonCard(),
                  SizedBox(height: 12),
                  CkSkeletonCard(),
                ],
              ),
              error: (e, _) => CkAlert(
                variant: CkAlertVariant.error,
                child: Text('Failed to load recipes: $e'),
              ),
              data: (recipes) => recipes.isEmpty
                  ? _EmptyRecipes(onBrowse: () {})
                  : ListView.builder(
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecipeListCard(recipe: recipe),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Browse Tab ───────────────────────────────────────────────────────────────

class _BrowseTab extends ConsumerStatefulWidget {
  final ValueChanged<String> onSearchChanged;
  const _BrowseTab({required this.onSearchChanged});

  @override
  ConsumerState<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<_BrowseTab> {
  static const _cuisines = [
    'All', 'Italian', 'French', 'Spanish', 'Portuguese',
    'Mexican', 'Chinese', 'Japanese', 'Indian', 'American',
  ];
  static const _categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];

  @override
  Widget build(BuildContext context) {
    final browseAsync = ref.watch(browseRecipesProvider);
    final selectedCuisine = ref.watch(browseCuisineProvider);
    final selectedCategory = ref.watch(browseCategoryProvider);
    final page = ref.watch(browsePageProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CkInput(
            placeholder: 'Search food database...',
            iconLeft: const Icon(LucideIcons.search, size: 16),
            fullWidth: true,
            onChanged: widget.onSearchChanged,
          ),
          const SizedBox(height: 10),
          // Cuisine filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _cuisines.map((c) {
                final isAll = c == 'All';
                final isSelected = isAll
                    ? selectedCuisine == null
                    : selectedCuisine == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(browseCuisineProvider.notifier).state =
                          isAll ? null : c;
                      ref.read(browsePageProvider.notifier).state = 1;
                    },
                    child: CkBadge(
                      variant: isSelected
                          ? CkBadgeVariant.success
                          : CkBadgeVariant.standard,
                      size: CkBadgeSize.sm,
                      child: Text(c),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final isAll = c == 'All';
                final isSelected = isAll
                    ? selectedCategory == null
                    : selectedCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(browseCategoryProvider.notifier).state =
                          isAll ? null : c;
                      ref.read(browsePageProvider.notifier).state = 1;
                    },
                    child: CkBadge(
                      variant: isSelected
                          ? CkBadgeVariant.info
                          : CkBadgeVariant.standard,
                      size: CkBadgeSize.sm,
                      child: Text(c),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: browseAsync.when(
              loading: () => ListView(
                children: const [
                  CkSkeletonCard(),
                  SizedBox(height: 12),
                  CkSkeletonCard(),
                  SizedBox(height: 12),
                  CkSkeletonCard(),
                ],
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.wifiOff, size: 40, color: context.appMuted),
                      const SizedBox(height: 12),
                      Text('Could not reach food database',
                          style: TextStyle(color: context.appMuted)),
                      const SizedBox(height: 4),
                      Text('Make sure the food-api service is running.',
                          style:
                              TextStyle(color: context.appMuted, fontSize: 12),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              data: (foodPage) => Column(
                children: [
                  if (foodPage.total > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${foodPage.total} recipes found',
                            style: TextStyle(
                                color: context.appMuted, fontSize: 12),
                          ),
                          if (foodPage.total > foodPage.perPage)
                            Row(
                              children: [
                                CkButton(
                                  variant: CkButtonVariant.ghost,
                                  size: CkButtonSize.sm,
                                  onPressed: page > 1
                                      ? () => ref
                                          .read(browsePageProvider.notifier)
                                          .state = page - 1
                                      : null,
                                  child: const Icon(LucideIcons.chevronLeft,
                                      size: 16),
                                ),
                                Text('$page',
                                    style:
                                        TextStyle(color: context.appMuted)),
                                CkButton(
                                  variant: CkButtonVariant.ghost,
                                  size: CkButtonSize.sm,
                                  onPressed: foodPage.recipes.length ==
                                          foodPage.perPage
                                      ? () => ref
                                          .read(browsePageProvider.notifier)
                                          .state = page + 1
                                      : null,
                                  child: const Icon(LucideIcons.chevronRight,
                                      size: 16),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: foodPage.recipes.isEmpty
                        ? Center(
                            child: Text('No recipes found',
                                style: TextStyle(color: context.appMuted)),
                          )
                        : ListView.builder(
                            itemCount: foodPage.recipes.length,
                            itemBuilder: (context, index) {
                              final item = foodPage.recipes[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _FoodRecipeCard(item: item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recipe list card (app-api) ───────────────────────────────────────────────

class _RecipeListCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeListCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return CkCard(
      variant: CkCardVariant.interactive,
      padding: CkCardPadding.md,
      onTap: () => context.push('/recipes/${recipe.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: recipe.primaryImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: recipe.primaryImageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => _imgPlaceholder(context),
                    errorWidget: (ctx, url, err) => _imgPlaceholder(context),
                  )
                : _imgPlaceholder(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.appHeading,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CkBadge(
                      variant: CkBadgeVariant.info,
                      size: CkBadgeSize.sm,
                      child: Text(recipe.category ?? 'Other'),
                    ),
                    const SizedBox(width: 8),
                    CkBadge(
                      variant: CkBadgeVariant.standard,
                      size: CkBadgeSize.sm,
                      child: Text(recipe.totalTimeMin != null
                          ? '${recipe.totalTimeMin} min'
                          : recipe.difficulty ?? 'easy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 16),
        ],
      ),
    );
  }

  Widget _imgPlaceholder(BuildContext context) => Container(
        width: 72,
        height: 72,
        color: context.appSurface,
        child: Icon(LucideIcons.utensils, size: 24, color: context.appMuted),
      );
}

// ── Food-api browse card ─────────────────────────────────────────────────────

class _FoodRecipeCard extends StatelessWidget {
  final FoodRecipeListItem item;
  const _FoodRecipeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return CkCard(
      variant: CkCardVariant.interactive,
      padding: CkCardPadding.md,
      onTap: () => context.push('/browse/recipes/${item.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.primaryImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.primaryImageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => _placeholder(context),
                    errorWidget: (ctx, url, err) => _placeholder(context),
                  )
                : _placeholder(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.appHeading,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    if (item.category != null)
                      CkBadge(
                        variant: CkBadgeVariant.info,
                        size: CkBadgeSize.sm,
                        child: Text(item.category!),
                      ),
                    if (item.cuisine != null)
                      CkBadge(
                        variant: CkBadgeVariant.standard,
                        size: CkBadgeSize.sm,
                        child: Text(item.cuisine!),
                      ),
                    if (item.totalTimeMin != null)
                      CkBadge(
                        variant: CkBadgeVariant.standard,
                        size: CkBadgeSize.sm,
                        child: Text('${item.totalTimeMin} min'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 16),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(LucideIcons.utensils, size: 24, color: context.appMuted),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyRecipes extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyRecipes({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bookOpen, size: 48, color: context.appMuted),
          const SizedBox(height: 12),
          Text('No recipes yet',
              style: TextStyle(color: context.appMuted, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Browse the food database to discover recipes',
              style: TextStyle(color: context.appMuted, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
