import 'package:flutter/foundation.dart';

@immutable
class GenIngredient {
  final String name;
  final double quantity;
  final String unit;
  final bool isPantryItem;

  const GenIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isPantryItem,
  });

  factory GenIngredient.fromJson(Map<String, dynamic> json) => GenIngredient(
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        isPantryItem: json['is_pantry_item'] as bool? ?? false,
      );
}

@immutable
class GenMacros {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const GenMacros({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });

  factory GenMacros.fromJson(Map<String, dynamic> json) => GenMacros(
        calories: (json['calories'] as num).toDouble(),
        proteinG: (json['protein_g'] as num).toDouble(),
        carbsG: (json['carbs_g'] as num).toDouble(),
        fatG: (json['fat_g'] as num).toDouble(),
        fiberG: (json['fiber_g'] as num).toDouble(),
      );
}

@immutable
class RecipeScore {
  /// Weighted overall score 0–10
  final double overall;

  /// LLM palatability judge 0–10 (weight 50 %)
  final double palatability;

  /// Nutritional balance 0–10 (weight 30 %)
  final double nutritionBalance;

  /// User preference / allergy match 0–10 (weight 20 %)
  final double preferenceMatch;

  final String palatabilityReason;

  /// How many refinement iterations were needed
  final int iterations;

  const RecipeScore({
    required this.overall,
    required this.palatability,
    required this.nutritionBalance,
    required this.preferenceMatch,
    required this.palatabilityReason,
    required this.iterations,
  });

  factory RecipeScore.fromJson(Map<String, dynamic> json) => RecipeScore(
        overall: (json['overall'] as num).toDouble(),
        palatability: (json['palatability'] as num).toDouble(),
        nutritionBalance: (json['nutrition_balance'] as num).toDouble(),
        preferenceMatch: (json['preference_match'] as num).toDouble(),
        palatabilityReason: json['palatability_reason'] as String? ?? '',
        iterations: json['iterations'] != null ? int.tryParse(json['iterations'].toString()) ?? 1 : 1,
      );

  /// Colour-coded label based on overall score
  String get label {
    if (overall >= 8.5) return 'Excecional';
    if (overall >= 7.0) return 'Muito bom';
    if (overall >= 5.5) return 'Razoável';
    return 'Melhorável';
  }
}

@immutable
class GeneratedRecipe {
  final String name;
  final String description;
  final String cuisine;
  final String difficulty;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final List<GenIngredient> ingredients;
  final List<String> steps;
  final GenMacros macrosPerServing;
  final List<String> tags;
  final RecipeScore score;

  const GeneratedRecipe({
    required this.name,
    required this.description,
    required this.cuisine,
    required this.difficulty,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.macrosPerServing,
    required this.tags,
    required this.score,
  });

  int get totalMinutes => prepMinutes + cookMinutes;

  factory GeneratedRecipe.fromJson(Map<String, dynamic> json) => GeneratedRecipe(
        name: json['name'] as String,
        description: json['description'] as String,
        cuisine: json['cuisine'] as String,
        difficulty: json['difficulty'] as String,
        prepMinutes: (json['prep_minutes'] as num).toInt(),
        cookMinutes: (json['cook_minutes'] as num).toInt(),
        servings: (json['servings'] as num).toInt(),
        ingredients: (json['ingredients'] as List)
            .map((e) => GenIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (json['steps'] as List).map((e) => e as String).toList(),
        macrosPerServing: GenMacros.fromJson(
            json['macros_per_serving'] as Map<String, dynamic>),
        tags: (json['tags'] as List).map((e) => e as String).toList(),
        score: RecipeScore.fromJson(json['score'] as Map<String, dynamic>),
      );
}
