import 'package:cookest_app/src/core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final suggestionRepositoryProvider = Provider<SuggestionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SuggestionRepository(apiClient);
});

class SuggestionRepository {
  final ApiClient _apiClient;

  SuggestionRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getSuggestions(int planId) async {
    final response = await _apiClient.get('/api/meal-plans/$planId/suggestions');
    final List<dynamic> data = response.data;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> createSuggestion(int planId, int slotId, int recipeId) async {
    await _apiClient.post('/api/meal-plans/$planId/suggestions', data: {
      'slot_id': slotId,
      'recipe_id': recipeId,
    });
  }

  Future<void> updateSuggestionStatus(int planId, int suggestionId, String status) async {
    await _apiClient.put('/api/meal-plans/$planId/suggestions/$suggestionId', data: {
      'status': status,
    });
  }
}
