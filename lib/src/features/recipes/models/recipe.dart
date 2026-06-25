class RecipeIngredient {
  final int id;
  final int ingredientId;
  final String name;
  final double? quantity;
  final String? unit;
  final double? quantityGrams;
  final String? notes;
  final int displayOrder;

  RecipeIngredient({
    required this.id,
    required this.ingredientId,
    required this.name,
    this.quantity,
    this.unit,
    this.quantityGrams,
    this.notes,
    required this.displayOrder,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    double? parseDecimal(dynamic v) =>
        v != null ? double.tryParse(v.toString()) : null;
    return RecipeIngredient(
      id: json['id'] as int? ?? 0,
      ingredientId: json['ingredient_id'] as int? ?? 0,
      name: json['ingredient_name']?.toString() ?? '',
      quantity: parseDecimal(json['quantity']),
      unit: json['unit']?.toString(),
      quantityGrams: parseDecimal(json['quantity_grams']),
      notes: json['notes']?.toString(),
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  String get display {
    final parts = <String>[];
    if (quantity != null) {
      parts.add(quantity! % 1 == 0
          ? quantity!.toInt().toString()
          : quantity!.toStringAsFixed(1));
    }
    if (unit != null && unit!.isNotEmpty) parts.add(unit!);
    parts.add(name);
    return parts.join(' ');
  }
}

class RecipeStep {
  final int id;
  final int stepNumber;
  final String instruction;
  final int? durationMin;
  final String? imageUrl;
  final String? tip;

  RecipeStep({
    required this.id,
    required this.stepNumber,
    required this.instruction,
    this.durationMin,
    this.imageUrl,
    this.tip,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      id: json['id'] as int? ?? 0,
      stepNumber: json['step_number'] as int? ?? 0,
      instruction: json['instruction']?.toString() ?? '',
      durationMin: json['duration_min'] as int?,
      imageUrl: json['image_url']?.toString(),
      tip: json['tip']?.toString(),
    );
  }
}

class RecipeImage {
  final int id;
  final String url;
  final String? imageType;
  final bool isPrimary;
  final int? width;
  final int? height;

  RecipeImage({
    required this.id,
    required this.url,
    this.imageType,
    required this.isPrimary,
    this.width,
    this.height,
  });

  factory RecipeImage.fromJson(Map<String, dynamic> json) {
    return RecipeImage(
      id: json['id'] as int? ?? 0,
      url: json['url']?.toString() ?? '',
      imageType: json['image_type']?.toString(),
      isPrimary: json['is_primary'] as bool? ?? false,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }
}

class RecipeNutrition {
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final double? saturatedFatG;
  final bool perServing;

  RecipeNutrition({
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.saturatedFatG,
    required this.perServing,
  });

  factory RecipeNutrition.fromJson(Map<String, dynamic> json) {
    double? p(dynamic v) => v != null ? double.tryParse(v.toString()) : null;
    return RecipeNutrition(
      calories: p(json['calories']),
      proteinG: p(json['protein_g']),
      carbsG: p(json['carbs_g']),
      fatG: p(json['fat_g']),
      fiberG: p(json['fiber_g']),
      sugarG: p(json['sugar_g']),
      sodiumMg: p(json['sodium_mg']),
      saturatedFatG: p(json['saturated_fat_g']),
      perServing: json['per_serving'] as bool? ?? true,
    );
  }
}

class Recipe {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String? cuisine;
  final String? category;
  final String? difficulty;
  final int? totalTimeMin;
  final int? prepTimeMin;
  final int? cookTimeMin;
  final int servings;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;
  final bool isNutFree;
  final double? matchPct;
  final String? primaryImageUrl;
  final List<RecipeImage> images;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final RecipeNutrition? nutrition;
  final String? sourceUrl;

  Recipe({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.cuisine,
    this.category,
    this.difficulty,
    this.totalTimeMin,
    this.prepTimeMin,
    this.cookTimeMin,
    this.servings = 4,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.isDairyFree = false,
    this.isNutFree = false,
    this.matchPct,
    this.primaryImageUrl,
    this.images = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.nutrition,
    this.sourceUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Recipe',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      cuisine: json['cuisine']?.toString(),
      category: json['category']?.toString(),
      difficulty: json['difficulty']?.toString(),
      totalTimeMin: json['total_time_min'] as int?,
      prepTimeMin: json['prep_time_min'] as int?,
      cookTimeMin: json['cook_time_min'] as int?,
      servings: json['servings'] as int? ?? 4,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isVegan: json['is_vegan'] as bool? ?? false,
      isGlutenFree: json['is_gluten_free'] as bool? ?? false,
      isDairyFree: json['is_dairy_free'] as bool? ?? false,
      isNutFree: json['is_nut_free'] as bool? ?? false,
      matchPct: json['match_pct'] != null ? double.tryParse(json['match_pct'].toString()) : null,
      primaryImageUrl: json['primary_image_url']?.toString(),
      images: (json['images'] as List? ?? [])
          .map((e) => RecipeImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List? ?? [])
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      nutrition: json['nutrition'] != null
          ? RecipeNutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
      sourceUrl: json['source_url']?.toString(),
    );
  }

  String? get bestImageUrl {
    if (primaryImageUrl != null) return primaryImageUrl;
    if (images.isNotEmpty) {
      final primary = images.where((i) => i.isPrimary).firstOrNull;
      return primary?.url ?? images.first.url;
    }
    return null;
  }
}
