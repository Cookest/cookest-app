import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/generated_recipe.dart';

/// Data-access layer for the AI recipe generation endpoint.
///
/// Communicates directly with [Dio] (bypassing [ApiClient]) so it can apply
/// a per-request receive timeout long enough for multi-step Ollama inference.
class RecipeGenRepository {
  final Dio _dio;

  RecipeGenRepository(this._dio);

  /// Calls POST /api/recipe-ai/generate.
  ///
  /// The server runs up to 3 generate→score→refine iterations silently and
  /// returns the best result. Expect 30–120 s on CPU-only hardware.
  Future<GeneratedRecipe> generate({
    required bool usePantry,
    String? cuisineHint,
    int? maxMinutes,
  }) async {
    final response = await _dio.post(
      '/api/recipe-ai/generate',
      data: {
        'use_pantry': usePantry,
        if (cuisineHint != null && cuisineHint.isNotEmpty)
          'cuisine_hint': cuisineHint,
        if (maxMinutes != null) 'max_minutes': maxMinutes,
      },
      options: Options(
        // Generation + up to 3 Ollama calls can take several minutes on CPU
        receiveTimeout: const Duration(minutes: 6),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    return GeneratedRecipe.fromJson(response.data as Map<String, dynamic>);
  }

  /// Calls POST /api/recipe-ai/save to persist a generated recipe into the
  /// user's recipes. Every ingredient must already be mapped to a catalog id.
  /// Returns the new recipe id.
  Future<int> save(GeneratedRecipe recipe) async {
    final response = await _dio.post(
      '/api/recipe-ai/save',
      data: recipe.toSaveJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return (data['id'] as num).toInt();
  }
}

/// Provider that exposes [RecipeGenRepository]. Depends on [dioProvider].
final recipeGenRepositoryProvider = Provider<RecipeGenRepository>((ref) {
  return RecipeGenRepository(ref.watch(dioProvider));
});

// ── State notifier ────────────────────────────────────────────────────────────

/// Base sealed class for AI recipe generation states.
sealed class RecipeGenState {
  const RecipeGenState();
}

/// Idle — no generation has been requested, or the last result was reset.
class RecipeGenIdle extends RecipeGenState {
  const RecipeGenIdle();
}

/// A generation request is in flight. The UI should show a progress indicator.
class RecipeGenLoading extends RecipeGenState {
  const RecipeGenLoading();
}

/// Generation completed successfully. [recipe] contains the AI-produced result.
class RecipeGenSuccess extends RecipeGenState {
  final GeneratedRecipe recipe;
  const RecipeGenSuccess(this.recipe);
}

/// Generation failed. [message] is a user-facing error string.
class RecipeGenError extends RecipeGenState {
  final String message;
  const RecipeGenError(this.message);
}

/// Orchestrates the AI recipe generation lifecycle: triggers the API call,
/// maps outcomes to [RecipeGenState] variants, and exposes [reset] to return
/// to idle after the user dismisses the result or error.
class RecipeGenNotifier extends StateNotifier<RecipeGenState> {
  final RecipeGenRepository _repo;

  RecipeGenNotifier(this._repo) : super(const RecipeGenIdle());

  Future<void> generate({
    required bool usePantry,
    String? cuisineHint,
    int? maxMinutes,
  }) async {
    state = const RecipeGenLoading();
    try {
      final recipe = await _repo.generate(
        usePantry: usePantry,
        cuisineHint: cuisineHint,
        maxMinutes: maxMinutes,
      );
      state = RecipeGenSuccess(recipe);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          'Erro ao gerar receita. Tenta novamente.';
      state = RecipeGenError(msg);
    } catch (e) {
      state = RecipeGenError('Erro inesperado: $e');
    }
  }

  void reset() => state = const RecipeGenIdle();
}

/// Provider that exposes [RecipeGenNotifier] / [RecipeGenState].
/// Depends on [recipeGenRepositoryProvider].
final recipeGenProvider =
    StateNotifierProvider<RecipeGenNotifier, RecipeGenState>((ref) {
  return RecipeGenNotifier(ref.watch(recipeGenRepositoryProvider));
});
