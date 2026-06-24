// ignore_for_file: dangling_library_doc_comments
/// Models for the food-api browse feature.

class FoodRecipeListItem {
  final int id;
  final String name;
  final String slug;
  final String? cuisine;
  final String? category;
  final String? difficulty;
  final int servings;
  final int? totalTimeMin;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;
  final double? averageRating;
  final int ratingCount;
  final String? primaryImageUrl;

  const FoodRecipeListItem({
    required this.id,
    required this.name,
    required this.slug,
    this.cuisine,
    this.category,
    this.difficulty,
    required this.servings,
    this.totalTimeMin,
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.isDairyFree,
    this.averageRating,
    required this.ratingCount,
    this.primaryImageUrl,
  });

  factory FoodRecipeListItem.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) => v != null ? double.tryParse(v.toString()) : null;
    return FoodRecipeListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      cuisine: json['cuisine'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      servings: json['servings'] as int? ?? 1,
      totalTimeMin: json['total_time_min'] as int?,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isVegan: json['is_vegan'] as bool? ?? false,
      isGlutenFree: json['is_gluten_free'] as bool? ?? false,
      isDairyFree: json['is_dairy_free'] as bool? ?? false,
      averageRating: parseDouble(json['average_rating']),
      ratingCount: json['rating_count'] as int? ?? 0,
      primaryImageUrl: json['primary_image_url'] as String?,
    );
  }
}

class FoodRecipePage {
  final List<FoodRecipeListItem> recipes;
  final int total;
  final int page;
  final int perPage;

  const FoodRecipePage({
    required this.recipes,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory FoodRecipePage.fromJson(Map<String, dynamic> json) {
    final list = ((json['data'] ?? json['recipes']) as List<dynamic>? ?? [])
        .map((e) => FoodRecipeListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return FoodRecipePage(
      recipes: list,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
    );
  }
}

class FoodRecipeIngredient {
  final String name;
  final double? quantity;
  final String? unit;
  final String? note;

  const FoodRecipeIngredient({
    required this.name,
    this.quantity,
    this.unit,
    this.note,
  });

  factory FoodRecipeIngredient.fromJson(Map<String, dynamic> json) {
    return FoodRecipeIngredient(
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      note: json['note'] as String?,
    );
  }
}

class FoodRecipeStep {
  final int stepNumber;
  final String instruction;
  final int? durationMin;
  final String? tip;
  final String? imageUrl;

  const FoodRecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.durationMin,
    this.tip,
    this.imageUrl,
  });

  factory FoodRecipeStep.fromJson(Map<String, dynamic> json) {
    return FoodRecipeStep(
      stepNumber: json['step_number'] as int? ?? 1,
      instruction: json['instruction']?.toString() ?? '',
      durationMin: json['duration_min'] as int?,
      tip: json['tip'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class FoodRecipeNutrition {
  final double? caloriesKcal;
  final double? proteinG;
  final double? fatG;
  final double? carbsG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;

  const FoodRecipeNutrition({
    this.caloriesKcal,
    this.proteinG,
    this.fatG,
    this.carbsG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
  });

  factory FoodRecipeNutrition.fromJson(Map<String, dynamic> json) {
    double? d(String k) => json[k] != null ? double.tryParse(json[k].toString()) : null;
    return FoodRecipeNutrition(
      caloriesKcal: d('calories_kcal'),
      proteinG: d('protein_g'),
      fatG: d('fat_g'),
      carbsG: d('carbs_g'),
      fiberG: d('fiber_g'),
      sugarG: d('sugar_g'),
      sodiumMg: d('sodium_mg'),
    );
  }
}

class FoodRecipeDetail {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? cuisine;
  final String? category;
  final String? difficulty;
  final int servings;
  final int? prepTimeMin;
  final int? cookTimeMin;
  final int? totalTimeMin;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;
  final bool isNutFree;
  final String? sourceUrl;
  final double? averageRating;
  final int ratingCount;
  final List<FoodRecipeIngredient> ingredients;
  final List<FoodRecipeStep> steps;
  final List<String> imageUrls;
  final FoodRecipeNutrition? nutrition;

  const FoodRecipeDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.cuisine,
    this.category,
    this.difficulty,
    required this.servings,
    this.prepTimeMin,
    this.cookTimeMin,
    this.totalTimeMin,
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.isDairyFree,
    required this.isNutFree,
    this.sourceUrl,
    this.averageRating,
    required this.ratingCount,
    required this.ingredients,
    required this.steps,
    required this.imageUrls,
    this.nutrition,
  });

  factory FoodRecipeDetail.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['url']?.toString() ?? '')
        .where((u) => u.isNotEmpty)
        .toList();
    return FoodRecipeDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      cuisine: json['cuisine'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      servings: json['servings'] as int? ?? 1,
      prepTimeMin: json['prep_time_min'] as int?,
      cookTimeMin: json['cook_time_min'] as int?,
      totalTimeMin: json['total_time_min'] as int?,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isVegan: json['is_vegan'] as bool? ?? false,
      isGlutenFree: json['is_gluten_free'] as bool? ?? false,
      isDairyFree: json['is_dairy_free'] as bool? ?? false,
      isNutFree: json['is_nut_free'] as bool? ?? false,
      sourceUrl: json['source_url'] as String?,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      ratingCount: json['rating_count'] as int? ?? 0,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => FoodRecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((e) => FoodRecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrls: images,
      nutrition: json['nutrition'] != null
          ? FoodRecipeNutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Image generation job result ───────────────────────────────────────────────

enum ImageGenStatus { pending, generating, done, failed }

class ImageGenJobResult {
  final String jobId;
  final ImageGenStatus status;
  final String? imageUrl;
  final String? error;

  const ImageGenJobResult({
    required this.jobId,
    required this.status,
    this.imageUrl,
    this.error,
  });

  bool get isDone => status == ImageGenStatus.done;
  bool get isFailed => status == ImageGenStatus.failed;
  bool get isProcessing =>
      status == ImageGenStatus.pending || status == ImageGenStatus.generating;

  factory ImageGenJobResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = switch (statusStr) {
      'done' => ImageGenStatus.done,
      'failed' => ImageGenStatus.failed,
      'generating' => ImageGenStatus.generating,
      _ => ImageGenStatus.pending,
    };
    return ImageGenJobResult(
      jobId: json['job_id'] as String? ?? '',
      status: status,
      imageUrl: json['image_url'] as String?,
      error: json['error'] as String?,
    );
  }
}
