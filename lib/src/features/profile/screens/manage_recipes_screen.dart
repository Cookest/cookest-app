import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../../recipes/repositories/recipe_repository.dart';
import '../../recipes/models/recipe.dart';

final myRecipesListProvider = FutureProvider.autoDispose<List<Recipe>>((ref) {
  return ref.watch(recipeRepositoryProvider).getMyRecipes();
});

class ManageRecipesScreen extends ConsumerWidget {
  const ManageRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(myRecipesListProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: Text(
          'My Recipes',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.appHeading,
          ),
        ),
      ),
      body: recipesAsync.when(
        loading: () => const Center(child: CkSpinner()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CkAlert(
              variant: CkAlertVariant.error,
              child: Text('Failed to load recipes: $e'),
            ),
          ),
        ),
        data: (recipes) {
          if (recipes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bookOpen, size: 48, color: context.appMuted),
                  const SizedBox(height: 12),
                  Text('No recipes yet',
                      style: TextStyle(color: context.appMuted, fontSize: 16)),
                  const SizedBox(height: 16),
                  CkButton(
                    variant: CkButtonVariant.primary,
                    onPressed: () => context.push('/recipes/create'),
                    child: const Text('Create Recipe'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myRecipesListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CkCard(
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
                                  if (recipe.isPublic == true)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: CkBadge(
                                        variant: CkBadgeVariant.success,
                                        size: CkBadgeSize.sm,
                                        child: const Text('Published'),
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: CkBadge(
                                        variant: CkBadgeVariant.standard,
                                        size: CkBadgeSize.sm,
                                        child: const Text('Private'),
                                      ),
                                    ),
                                  if (recipe.category != null)
                                    CkBadge(
                                      variant: CkBadgeVariant.info,
                                      size: CkBadgeSize.sm,
                                      child: Text(recipe.category!),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recipes/create'),
        backgroundColor: CookestTokens.colorPrimaryDEFAULT,
        child: const Icon(LucideIcons.plus, color: Colors.white),
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
