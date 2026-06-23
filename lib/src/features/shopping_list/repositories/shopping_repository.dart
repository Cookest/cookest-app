import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/shopping_item.dart';

class ShoppingRepository {
  final Dio _dio;

  ShoppingRepository(this._dio);

  Future<List<ShoppingItem>> getShoppingList() async {
    final response = await _dio.get('/api/shopping-list');
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
        .whereType<Map>()
        .map((i) => ShoppingItem.fromJson(Map<String, dynamic>.from(i)))
        .toList();
  }

  Future<void> syncFromPlan() async {
    // 1. Fetch the ingredients needed for the current meal plan
    final planResponse = await _dio.get('/api/meal-plans/current/shopping-list');
    final List planItems = planResponse.data is List ? planResponse.data : [];
    
    // 2. Map the response to the format expected by the sync endpoint
    final itemsToSync = planItems.map((item) => {
      'ingredient_id': item['ingredient_id'],
      'name': item['name'],
      'quantity': item['to_buy_grams'],
      'unit': 'g', // The backend currently returns 'grams' for everything in this heuristic
    }).toList();

    // 3. Sync with the shopping list
    await _dio.post('/api/shopping-list/sync', data: {'items': itemsToSync});
  }

  Future<void> addItem(String name, double quantity, String unit) async {
    await _dio.post('/api/shopping-list/items', data: {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    });
  }

  Future<void> toggleCheck(String id, bool isChecked) async {
    await _dio.patch('/api/shopping-list/items/$id/check', data: {
      'is_checked': isChecked,
    });
  }

  Future<void> deleteItem(String id) async {
    await _dio.delete('/api/shopping-list/items/$id');
  }

  Future<Map<String, dynamic>> getPrices() async {
    // Pro feature
    final response = await _dio.get('/api/shopping-list/prices');
    return response.data;
  }

  Future<Map<String, dynamic>> optimize() async {
    // Pro feature
    final response = await _dio.get('/api/shopping-list/optimize');
    return response.data;
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(dioProvider));
});

final shoppingListProvider = FutureProvider<List<ShoppingItem>>((ref) async {
  return ref.watch(shoppingRepositoryProvider).getShoppingList();
});
