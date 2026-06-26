import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/recipe.dart';

class RecipeRepository {
  final Dio _dio;

  RecipeRepository(this._dio);

  Future<List<Recipe>> getRecipes({
    String? q,
    String? cuisine,
    String? category,
    bool? matchInventory,
    int page = 1,
  }) async {
    final response = await _dio.get('/api/recipes', queryParameters: {
      if (q != null) 'q': q,
      if (cuisine != null) 'cuisine': cuisine,
      if (category != null) 'category': category,
      if (matchInventory != null) 'match_inventory': matchInventory,
      'page': page,
      'per_page': 20,
    });
    
    final data = response.data;
    final List items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else {
      items = [];
    }
    return items.map((r) => Recipe.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Recipe>> getMyRecipes({
    String? q,
    String? cuisine,
    String? category,
    int page = 1,
  }) async {
    final response = await _dio.get('/api/recipes/mine', queryParameters: {
      if (q != null) 'q': q,
      if (cuisine != null) 'cuisine': cuisine,
      if (category != null) 'category': category,
      'page': page,
      'per_page': 20,
    });
    
    final data = response.data;
    final List items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else {
      items = [];
    }
    return items.map((r) => Recipe.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Recipe> getRecipe(String id) async {
    final response = await _dio.get('/api/recipes/$id');
    return Recipe.fromJson(response.data);
  }

  Future<Recipe> createRecipe(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/recipes', data: data);
      return Recipe.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        throw 'Creating recipes is a Pro feature. Please upgrade.';
      }
      throw e.response?.data['error'] ?? 'Failed to create recipe.';
    }
  }

  Future<String> uploadRecipeImage(String recipeId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('/api/recipes/$recipeId/image', data: formData);
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to upload recipe image.';
    }
  }

  Future<Map<String, dynamic>> importRecipe(String id) async {
    try {
      final response = await _dio.post('/api/recipes/$id/import');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to import recipe.';
    }
  }
}

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(dioProvider));
});
