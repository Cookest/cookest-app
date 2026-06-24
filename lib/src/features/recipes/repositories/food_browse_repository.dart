import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/food_recipe.dart';

class FoodBrowseRepository {
  final Dio _dio;

  FoodBrowseRepository(this._dio);

  Future<FoodRecipePage> searchRecipes({
    String? q,
    String? cuisine,
    String? category,
    String? difficulty,
    bool? vegetarian,
    bool? vegan,
    bool? glutenFree,
    int? maxTime,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get('/api/browse/recipes', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (cuisine != null) 'cuisine': cuisine,
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
      if (vegetarian == true) 'vegetarian': true,
      if (vegan == true) 'vegan': true,
      if (glutenFree == true) 'gluten_free': true,
      if (maxTime != null) 'max_time': maxTime,
      'page': page,
      'per_page': perPage,
    });

    final data = response.data;
    if (data is Map<String, dynamic>) {
      // food-api wraps in { data: [...], total, page, per_page } (or recipes: [...])
      if (data['data'] is List || data['recipes'] is List) {
        return FoodRecipePage.fromJson(data);
      }
      // fallback: bare list
    }
    if (data is List) {
      return FoodRecipePage(
        recipes: data
            .map((e) => FoodRecipeListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: data.length,
        page: page,
        perPage: perPage,
      );
    }
    return FoodRecipePage(recipes: [], total: 0, page: page, perPage: perPage);
  }

  Future<FoodRecipeDetail> getRecipe(int id) async {
    final response = await _dio.get('/api/browse/recipes/$id');
    return FoodRecipeDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// Trigger AI image generation for all steps of a recipe.
  /// Returns a map of step_index → job_id.
  Future<Map<int, String>> generateStepImages(FoodRecipeDetail recipe) async {
    final steps = recipe.steps
        .map((s) => {
              'step_index': s.stepNumber - 1,
              'step_description': s.instruction,
            })
        .toList();

    final response = await _dio.post(
      '/api/image-gen/recipes/${recipe.id}/steps/batch',
      data: {
        'recipe_name': recipe.name,
        'cuisine': recipe.cuisine,
        'steps': steps,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final jobs = (data['jobs'] as List<dynamic>? ?? []);
    return {
      for (final j in jobs)
        (j['step_index'] as int): j['job_id'] as String,
    };
  }

  /// Generate hero image for a recipe.
  Future<String> generateHeroImage(FoodRecipeDetail recipe) async {
    final response = await _dio.post(
      '/api/image-gen/recipes/${recipe.id}/hero',
      data: {
        'recipe_name': recipe.name,
        'description': recipe.description,
        'cuisine': recipe.cuisine,
        'category': recipe.category,
      },
    );
    return (response.data as Map<String, dynamic>)['job_id'] as String;
  }

  /// Poll a generation job.
  Future<ImageGenJobResult> pollJob(String jobId) async {
    final response = await _dio.get('/api/image-gen/jobs/$jobId');
    return ImageGenJobResult.fromJson(response.data as Map<String, dynamic>);
  }

}

final foodBrowseRepositoryProvider = Provider<FoodBrowseRepository>((ref) {
  return FoodBrowseRepository(ref.watch(dioProvider));
});

/// Providers for browse state
final browseSearchProvider = StateProvider<String>((ref) => '');
final browseCuisineProvider = StateProvider<String?>((ref) => null);
final browseCategoryProvider = StateProvider<String?>((ref) => null);
final browsePageProvider = StateProvider<int>((ref) => 1);

final browseRecipesProvider = FutureProvider<FoodRecipePage>((ref) {
  final q = ref.watch(browseSearchProvider);
  final cuisine = ref.watch(browseCuisineProvider);
  final category = ref.watch(browseCategoryProvider);
  final page = ref.watch(browsePageProvider);
  return ref.watch(foodBrowseRepositoryProvider).searchRecipes(
        q: q.isEmpty ? null : q,
        cuisine: cuisine,
        category: category,
        page: page,
      );
});

final browseFoodDetailProvider =
    FutureProvider.family<FoodRecipeDetail, int>((ref, id) {
  return ref.watch(foodBrowseRepositoryProvider).getRecipe(id);
});
