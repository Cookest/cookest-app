import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

/// A nutrition-aware grocery suggestion from the AI.
class BuySuggestion {
  final String item;
  final String reason;
  final String? nutrient;
  final double? amount;
  final String? unit;

  const BuySuggestion({
    required this.item, 
    required this.reason, 
    this.nutrient,
    this.amount,
    this.unit,
  });

  factory BuySuggestion.fromJson(Map<String, dynamic> j) => BuySuggestion(
        item: j['item']?.toString() ?? '',
        reason: j['reason']?.toString() ?? '',
        nutrient: j['nutrient']?.toString(),
        amount: (j['amount'] as num?)?.toDouble(),
        unit: j['unit']?.toString(),
      );
}

class NutritionRepository {
  final Dio _dio;
  NutritionRepository(this._dio);

  /// RAG-grounded "what to buy" suggestions. Long receive timeout because the
  /// local LLM can take a while on CPU.
  Future<List<BuySuggestion>> whatToBuy({String? goal}) async {
    final resp = await _dio.post(
      '/api/ai/what-to-buy',
      data: {if (goal != null && goal.isNotEmpty) 'goal': goal},
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    final data = resp.data;
    final List items = (data is Map && data['suggestions'] is List)
        ? data['suggestions'] as List
        : [];
    return items
        .map((e) => BuySuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(dioProvider));
});

/// What-to-buy suggestions for an optional goal string ('' = general).
final whatToBuyProvider =
    FutureProvider.autoDispose.family<List<BuySuggestion>, String>((ref, goal) async {
  return ref.watch(nutritionRepositoryProvider).whatToBuy(goal: goal.isEmpty ? null : goal);
});
