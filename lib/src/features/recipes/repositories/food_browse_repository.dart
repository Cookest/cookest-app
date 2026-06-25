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
