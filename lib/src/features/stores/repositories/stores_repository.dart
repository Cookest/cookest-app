import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/store.dart';

class StoresRepository {
  final Dio _dio;
  StoresRepository(this._dio);

  Future<List<NearbyStore>> getNearby(
    double lat,
    double lng, {
    double radiusKm = 5,
  }) async {
    final resp = await _dio.get(
      '/api/stores/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius_km': radiusKm},
    );
    return _stores(resp.data);
  }

  Future<List<Promotion>> getStorePromotions(String storeId) async {
    final resp = await _dio.get('/api/stores/$storeId/promotions');
    return _promotions(resp.data);
  }

  /// Cheapest active promotions for an ingredient (Pro feature).
  Future<List<Promotion>> getIngredientPrices(int ingredientId) async {
    final resp = await _dio.get('/api/ingredients/$ingredientId/prices');
    return _promotions(resp.data);
  }

  List<NearbyStore> _stores(dynamic data) {
    final List items = (data is Map && data['stores'] is List)
        ? data['stores'] as List
        : (data is List ? data : []);
    return items
        .map((e) => NearbyStore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Promotion> _promotions(dynamic data) {
    final List items = (data is Map && data['promotions'] is List)
        ? data['promotions'] as List
        : (data is List ? data : []);
    return items
        .map((e) => Promotion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final storesRepositoryProvider = Provider<StoresRepository>((ref) {
  return StoresRepository(ref.watch(dioProvider));
});

/// Nearby supermarkets for a (lat, lng) point. Family key is a positional
/// record so identical coordinates reuse the cached result.
final nearbyStoresProvider =
    FutureProvider.family<List<NearbyStore>, (double, double)>((ref, p) async {
  return ref.watch(storesRepositoryProvider).getNearby(p.$1, p.$2);
});

final storePromotionsProvider =
    FutureProvider.family<List<Promotion>, String>((ref, storeId) async {
  return ref.watch(storesRepositoryProvider).getStorePromotions(storeId);
});
