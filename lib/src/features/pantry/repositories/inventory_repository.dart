import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/inventory_item.dart';

class InventoryRepository {
  final Dio _dio;

  InventoryRepository(this._dio);

  Future<List<InventoryItem>> getInventory() async {
    final response = await _dio.get('/api/inventory');
    final data = response.data;
    final List items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['items'] is List) {
      items = data['items'] as List;
    } else {
      items = [];
    }
    return items
        .map((i) => InventoryItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<InventoryItem> addItem(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/inventory/quick', data: data);
    return InventoryItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _dio.put('/api/inventory/$id', data: data);
  }

  Future<void> deleteItem(String id) async {
    await _dio.delete('/api/inventory/$id');
  }

  Future<int> getExpiringCount() async {
    try {
      final response = await _dio.get('/api/inventory/expiring');
      final data = response.data;
      if (data is List) return data.length;
      if (data is Map && data['items'] is List) {
        return (data['items'] as List).length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<IngredientSuggestion>> searchIngredients(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _dio.get(
      '/api/ingredients',
      queryParameters: {'q': query.trim(), 'per_page': 10},
    );
    final data = response.data;
    final List items;
    if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }
    return items
        .map((i) => IngredientSuggestion.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecipeSuggestion>> getRecipeSuggestions() async {
    try {
      final response = await _dio.get('/api/inventory/suggestions');
      final data = response.data;
      final List items = data is List ? data : [];
      return items
          .map((i) => RecipeSuggestion.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<DetectedGroceryItem>> scanImage(List<int> imageBytes) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(imageBytes, filename: 'scan.jpg'),
    });
    final response = await _dio.post(
      '/api/inventory/scan',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    final data = response.data;
    final List items =
        (data is Map ? data['items'] : data) as List? ?? [];
    return items
        .map((i) => DetectedGroceryItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryItem>> bulkAdd(
      List<Map<String, dynamic>> items) async {
    final response =
        await _dio.post('/api/inventory/bulk', data: items);
    final data = response.data as List;
    return data
        .map((i) => InventoryItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  /// Resolve a scanned barcode via FatSecret and add it to the pantry.
  Future<void> addByBarcode(
    String barcode,
    double quantity,
    String unit, {
    String? storageLocation,
  }) async {
    await _dio.post('/api/inventory/barcode', data: {
      'barcode': barcode,
      'quantity': quantity,
      'unit': unit,
      if (storageLocation != null) 'storage_location': storageLocation,
    });
  }

  /// Manually use up part of a pantry item.
  Future<void> consumeItem(String id, double quantity) async {
    await _dio.post('/api/inventory/$id/consume', data: {'quantity': quantity});
  }

  /// Mark a recipe cooked — the backend deducts ingredients from the pantry.
  Future<void> cookRecipe(String recipeId, int servingsMade) async {
    await _dio.post('/api/recipes/$recipeId/cook',
        data: {'servings_made': servingsMade});
  }

  /// Undo a cook, restoring the deducted inventory.
  Future<void> undoCook(String historyId) async {
    await _dio.post('/api/cooking-history/$historyId/undo');
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(dioProvider));
});

final expiringCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(inventoryRepositoryProvider).getExpiringCount();
});

final inventoryListProvider = FutureProvider<List<InventoryItem>>((ref) async {
  return ref.watch(inventoryRepositoryProvider).getInventory();
});

final recipeSuggestionsProvider =
    FutureProvider<List<RecipeSuggestion>>((ref) async {
  return ref.watch(inventoryRepositoryProvider).getRecipeSuggestions();
});

