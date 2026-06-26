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

final globalSearchProvider = StateProvider<String>((ref) => '');
final globalCuisineProvider = StateProvider<String?>((ref) => null);
final globalCategoryProvider = StateProvider<String?>((ref) => null);

final globalRecipesProvider = FutureProvider<List<FoodRecipeListItem>>((ref) async {
  final query = ref.watch(globalSearchProvider);
  final cuisine = ref.watch(globalCuisineProvider);
  final category = ref.watch(globalCategoryProvider);
  
  final res = await ref.watch(foodBrowseRepositoryProvider).searchRecipes(
    q: query.isEmpty ? null : query,
    cuisine: cuisine,
    category: category,
    page: 1,
    perPage: 30,
  );
  return res.recipes;
});

final communitySearchProvider = StateProvider<String>((ref) => '');
final communityCuisineProvider = StateProvider<String?>((ref) => null);
final communityCategoryProvider = StateProvider<String?>((ref) => null);

final communityRecipesProvider = FutureProvider<List<Recipe>>((ref) {
  final query = ref.watch(communitySearchProvider);
  final cuisine = ref.watch(communityCuisineProvider);
  final category = ref.watch(communityCategoryProvider);
  
  return ref.watch(recipeRepositoryProvider).getRecipes(
    q: query.isEmpty ? null : query,
    cuisine: cuisine,
    category: category,
  );
});

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  String _activeTab = 'global';
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
      ref.read(globalSearchProvider.notifier).state = value;
    });
  }

  void _onBrowseSearchChanged(String value) {
    _browseDebounce?.cancel();
    _browseDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(communitySearchProvider.notifier).state = value;
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
                CkTabItem(id: 'global', label: 'Global Recipes'),
                CkTabItem(id: 'browse', label: 'Browse Community'),
              ],
            ),
          ),
          Expanded(
            child: _activeTab == 'global'
                ? _GlobalTab(
                    onSearchChanged: _onSearchChanged,
                  )
                : _BrowseTab(onSearchChanged: _onBrowseSearchChanged),
          ),
        ],
      ),
    );
  }
}

// ── Global Tab ───────────────────────────────────────────────────────────────

class _GlobalTab extends ConsumerStatefulWidget {
  final ValueChanged<String> onSearchChanged;

  const _GlobalTab({
    required this.onSearchChanged,
  });

  @override
  ConsumerState<_GlobalTab> createState() => _GlobalTabState();
}

class _GlobalTabState extends ConsumerState<_GlobalTab> {
  static const _cuisines = [
    'All', 'Italian', 'French', 'Spanish', 'Portuguese',
    'Mexican', 'Chinese', 'Japanese', 'Indian', 'American',
  ];
  static const _categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(globalRecipesProvider);
    final selectedCuisine = ref.watch(globalCuisineProvider);
    final selectedCategory = ref.watch(globalCategoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CkInput(
            placeholder: 'Search global recipes...',
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
                      ref.read(globalCuisineProvider.notifier).state =
                          isAll ? null : c;
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
                      ref.read(globalCategoryProvider.notifier).state =
                          isAll ? null : c;
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
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CkAlert(
                    variant: CkAlertVariant.error,
                    child: Text('Failed to load recipes: $e'),
                  ),
                ),
              ),
              data: (recipes) => Column(
                children: [
                  Expanded(
                    child: recipes.isEmpty
                        ? Center(
                            child: Text('No global recipes found',
                                style: TextStyle(color: context.appMuted)),
                          )
                        : ListView.builder(
                            itemCount: recipes.length,
                            itemBuilder: (context, index) {
                              final recipe = recipes[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _FoodRecipeCard(item: recipe),
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
    final browseAsync = ref.watch(communityRecipesProvider);
    final selectedCuisine = ref.watch(communityCuisineProvider);
    final selectedCategory = ref.watch(communityCategoryProvider);

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
                      ref.read(communityCuisineProvider.notifier).state =
                          isAll ? null : c;
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
                      ref.read(communityCategoryProvider.notifier).state =
                          isAll ? null : c;
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
                  child: CkAlert(
                    variant: CkAlertVariant.error,
                    child: Text('Failed to load recipes: $e'),
                  ),
                ),
              ),
              data: (recipes) => Column(
                children: [
                  Expanded(
                    child: recipes.isEmpty
                        ? Center(
                            child: Text('No community recipes found',
                                style: TextStyle(color: context.appMuted)),
                          )
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
