import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

class MockApiInterceptor extends Interceptor {
  final _state = _MockApiState();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = _normalizePath(options.path);
    if (!path.startsWith('/api/')) {
      handler.next(options);
      return;
    }

    final result = _state.handle(options, path);
    if (result == null) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            data: {'error': 'Demo endpoint not found: $path'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: result.statusCode,
        data: result.data,
      ),
    );
  }

  String _normalizePath(String rawPath) {
    final parsed = Uri.tryParse(rawPath);
    if (parsed == null) return rawPath;
    if (parsed.path.isEmpty) return rawPath;
    return parsed.path;
  }
}

class _MockResult {
  final int statusCode;
  final dynamic data;

  const _MockResult(this.statusCode, this.data);
}

class _MockApiState {
  int _nextInventoryId = 300;
  int _nextShoppingId = 500;
  int _nextRecipeId = 1000;
  int _nextMealSlotId = 900;
  int _nextChatSessionId = 1;
  int _nextChatMessageId = 1;

  final Map<int, int> _chatTurns = {};

  final Map<String, dynamic> _profile = {
    'id': 'demo-user',
    'email': 'demo@cookest.app',
    'name': 'Demo Chef',
    'household_size': 2,
    'dietary_restrictions': <String>['high-protein'],
    'allergies': <String>[],
    'avatar_url': null,
    'is_email_verified': true,
    'two_factor_enabled': false,
    'created_at': '2026-01-08T10:00:00Z',
  };

  final Map<String, dynamic> _subscription = {
    'tier': 'pro',
    'features': [
      'ai_chat',
      'meal_plan',
      'recipe_generation',
      'pantry_tracking',
    ],
    'valid_until': '2027-01-01T00:00:00Z',
  };

  late final List<Map<String, dynamic>> _recipes = [
    _seedRecipe(
      id: 1,
      name: 'Mediterranean Chicken Bowl',
      cuisine: 'Mediterranean',
      category: 'Dinner',
      difficulty: 'Easy',
      prep: 12,
      cook: 18,
      servings: 2,
      vegetarian: false,
      tags: ['protein', 'balanced'],
      imageSeed: 'mediterranean-bowl',
      ingredients: [
        'Chicken breast',
        'Cherry tomatoes',
        'Cucumber',
        'Greek yogurt',
        'Olive oil',
      ],
      steps: [
        'Season and grill the chicken until cooked through.',
        'Chop tomatoes and cucumber, then toss with olive oil.',
        'Slice chicken and serve over salad with a yogurt drizzle.',
      ],
      macros: {'calories': 520, 'protein_g': 41, 'carbs_g': 26, 'fat_g': 28},
    ),
    _seedRecipe(
      id: 2,
      name: 'Portuguese Bacalhau à Brás',
      cuisine: 'Portuguese',
      category: 'Dinner',
      difficulty: 'Medium',
      prep: 20,
      cook: 20,
      servings: 3,
      vegetarian: false,
      tags: ['traditional', 'comfort'],
      imageSeed: 'bacalhau-bras',
      ingredients: ['Salt cod', 'Eggs', 'Potatoes', 'Onion', 'Parsley'],
      steps: [
        'Soak cod, shred it, and saute onion until soft.',
        'Add cod and potato sticks, then fold gently.',
        'Stir in eggs over low heat and finish with parsley.',
      ],
      macros: {'calories': 610, 'protein_g': 38, 'carbs_g': 41, 'fat_g': 30},
    ),
    _seedRecipe(
      id: 3,
      name: 'Creamy Mushroom Pasta',
      cuisine: 'Italian',
      category: 'Lunch',
      difficulty: 'Easy',
      prep: 10,
      cook: 15,
      servings: 2,
      vegetarian: true,
      tags: ['vegetarian', 'quick'],
      imageSeed: 'mushroom-pasta',
      ingredients: ['Pasta', 'Mushrooms', 'Garlic', 'Cream', 'Parmesan'],
      steps: [
        'Cook pasta in salted boiling water.',
        'Saute mushrooms and garlic until golden.',
        'Add cream, toss in pasta, and finish with parmesan.',
      ],
      macros: {'calories': 560, 'protein_g': 18, 'carbs_g': 67, 'fat_g': 24},
    ),
    _seedRecipe(
      id: 4,
      name: 'Overnight Oats with Berries',
      cuisine: 'International',
      category: 'Breakfast',
      difficulty: 'Easy',
      prep: 8,
      cook: 0,
      servings: 1,
      vegetarian: true,
      vegan: true,
      tags: ['breakfast', 'meal-prep'],
      imageSeed: 'overnight-oats',
      ingredients: [
        'Oats',
        'Chia seeds',
        'Almond milk',
        'Blueberries',
        'Honey',
      ],
      steps: [
        'Mix oats, chia, and milk in a jar.',
        'Chill overnight.',
        'Top with berries and honey before serving.',
      ],
      macros: {'calories': 380, 'protein_g': 12, 'carbs_g': 50, 'fat_g': 14},
    ),
    _seedRecipe(
      id: 5,
      name: 'Salmon Tray Bake',
      cuisine: 'Nordic',
      category: 'Dinner',
      difficulty: 'Medium',
      prep: 10,
      cook: 25,
      servings: 2,
      vegetarian: false,
      glutenFree: true,
      tags: ['omega-3', 'sheet-pan'],
      imageSeed: 'salmon-tray',
      ingredients: [
        'Salmon fillet',
        'Potatoes',
        'Broccoli',
        'Lemon',
        'Olive oil',
      ],
      steps: [
        'Roast potatoes until nearly tender.',
        'Add salmon and broccoli, season well.',
        'Bake until salmon flakes and finish with lemon.',
      ],
      macros: {'calories': 590, 'protein_g': 44, 'carbs_g': 34, 'fat_g': 30},
    ),
    _seedRecipe(
      id: 6,
      name: 'Chickpea Tomato Stew',
      cuisine: 'Spanish',
      category: 'Dinner',
      difficulty: 'Easy',
      prep: 8,
      cook: 22,
      servings: 3,
      vegetarian: true,
      vegan: true,
      dairyFree: true,
      tags: ['vegan', 'batch-cook'],
      imageSeed: 'chickpea-stew',
      ingredients: ['Chickpeas', 'Tomatoes', 'Onion', 'Paprika', 'Spinach'],
      steps: [
        'Saute onion with paprika until fragrant.',
        'Add tomatoes and chickpeas, simmer gently.',
        'Fold in spinach and season before serving.',
      ],
      macros: {'calories': 430, 'protein_g': 17, 'carbs_g': 58, 'fat_g': 12},
    ),
  ];

  late final List<Map<String, dynamic>> _inventory = [
    _inventoryItem(
      id: '301',
      ingredientId: 1201,
      name: 'Chicken breast',
      quantity: 600,
      unit: 'g',
      location: 'fridge',
      daysFromNow: 2,
    ),
    _inventoryItem(
      id: '302',
      ingredientId: 1202,
      name: 'Eggs',
      quantity: 6,
      unit: 'pcs',
      location: 'fridge',
      daysFromNow: 7,
    ),
    _inventoryItem(
      id: '303',
      ingredientId: 1203,
      name: 'Pasta',
      quantity: 1,
      unit: 'pack',
      location: 'pantry',
      daysFromNow: 60,
    ),
    _inventoryItem(
      id: '304',
      ingredientId: 1204,
      name: 'Tomatoes',
      quantity: 4,
      unit: 'pcs',
      location: 'fridge',
      daysFromNow: 1,
    ),
    _inventoryItem(
      id: '305',
      ingredientId: 1205,
      name: 'Olive oil',
      quantity: 1,
      unit: 'bottle',
      location: 'pantry',
      daysFromNow: 90,
    ),
  ];

  late final List<Map<String, dynamic>> _shopping = [
    {
      'id': '501',
      'name': 'Greek yogurt',
      'quantity': 1.0,
      'unit': 'pack',
      'is_checked': false,
    },
    {
      'id': '502',
      'name': 'Blueberries',
      'quantity': 250.0,
      'unit': 'g',
      'is_checked': false,
    },
    {
      'id': '503',
      'name': 'Lemon',
      'quantity': 2.0,
      'unit': 'pcs',
      'is_checked': true,
    },
  ];

  late Map<String, dynamic> _mealPlan = _buildMealPlan();

  _MockResult? handle(RequestOptions options, String path) {
    final method = options.method.toUpperCase();
    final segments = Uri.parse(path).pathSegments;

    if (method == 'POST' && path == '/api/auth/login') {
      return _ok({'access_token': 'demo-token'});
    }
    if (method == 'POST' && path == '/api/auth/register') {
      return _ok({'ok': true}, 201);
    }
    if (method == 'POST' && path == '/api/auth/refresh') {
      return _ok({'access_token': 'demo-token'});
    }
    if (method == 'POST' && path == '/api/auth/logout') {
      return _ok({'ok': true});
    }

    if (method == 'POST' && path == '/api/me/onboarding') {
      final data = _asMap(options.data);
      _profile['household_size'] =
          (data['household_size'] as num?)?.toInt() ??
          (_profile['household_size'] as int);
      if (data['dietary_restrictions'] is List) {
        _profile['dietary_restrictions'] = List<String>.from(
          data['dietary_restrictions'] as List,
        );
      }
      if (data['allergies'] is List) {
        _profile['allergies'] = List<String>.from(data['allergies'] as List);
      }
      return _ok({'ok': true});
    }

    if (method == 'GET' && path == '/api/me') {
      return _ok(_copy(_profile));
    }
    if (method == 'PUT' && path == '/api/me') {
      final data = _asMap(options.data);
      if (data.containsKey('name')) _profile['name'] = data['name'];
      if (data.containsKey('household_size')) {
        _profile['household_size'] =
            (data['household_size'] as num?)?.toInt() ??
            _profile['household_size'];
      }
      if (data['dietary_restrictions'] is List) {
        _profile['dietary_restrictions'] = List<String>.from(
          data['dietary_restrictions'] as List,
        );
      }
      if (data['allergies'] is List) {
        _profile['allergies'] = List<String>.from(data['allergies'] as List);
      }
      return _ok(_copy(_profile));
    }
    if (method == 'DELETE' && path == '/api/me/preferences') {
      return _ok({'ok': true});
    }
    if (method == 'GET' && path == '/api/subscription') {
      return _ok(_copy(_subscription));
    }

    if (method == 'GET' && path == '/api/meal-plans/current') {
      return _ok(_copy(_mealPlan));
    }
    if (method == 'POST' && path == '/api/meal-plans/generate') {
      _mealPlan = _buildMealPlan(shuffle: true);
      return _ok({'ok': true});
    }
    if (segments.length == 4 &&
        method == 'GET' &&
        segments[0] == 'api' &&
        segments[1] == 'meal-plans' &&
        segments[3] == 'nutrition') {
      final nutrition = _mealPlan['nutrition'] as Map<String, dynamic>;
      return _ok(_copy(nutrition));
    }
    if (segments.length == 6 &&
        method == 'PUT' &&
        segments[0] == 'api' &&
        segments[1] == 'meal-plans' &&
        segments[3] == 'slots' &&
        segments[5] == 'complete') {
      final slotId = segments[4];
      final slot = _findSlot(slotId);
      if (slot == null) return _error('Slot not found', 404);
      slot['is_completed'] = true;
      return _ok({'ok': true});
    }
    if (segments.length == 6 &&
        method == 'PUT' &&
        segments[0] == 'api' &&
        segments[1] == 'meal-plans' &&
        segments[3] == 'slots' &&
        segments[5] == 'flex') {
      final slotId = segments[4];
      final data = _asMap(options.data);
      final slot = _findSlot(slotId);
      if (slot == null) return _error('Slot not found', 404);
      slot['is_flex'] = true;
      slot['flex_type'] = data['flex_type']?.toString() ?? 'leftovers';
      return _ok({'ok': true});
    }
    if (segments.length == 5 &&
        method == 'PUT' &&
        segments[0] == 'api' &&
        segments[1] == 'meal-plans' &&
        segments[3] == 'slots') {
      final slotId = segments[4];
      final data = _asMap(options.data);
      final recipeId = data['recipe_id']?.toString();
      final slot = _findSlot(slotId);
      final recipe = recipeId == null ? null : _findRecipe(recipeId);
      if (slot == null || recipe == null) {
        return _error('Invalid slot/recipe', 400);
      }
      slot['recipe'] = _toMealRecipeSummary(recipe);
      slot['is_flex'] = false;
      slot['flex_type'] = null;
      slot['is_completed'] = false;
      return _ok({'ok': true});
    }
    if (segments.length == 4 &&
        method == 'POST' &&
        segments[0] == 'api' &&
        segments[1] == 'meal-plans' &&
        segments[3] == 'slots') {
      final data = _asMap(options.data);
      final recipeId = data['recipe_id']?.toString();
      final dayOfWeek = (data['day_of_week'] as num?)?.toInt();
      final mealType = data['meal_type']?.toString();
      final recipe = recipeId == null ? null : _findRecipe(recipeId);
      if (dayOfWeek == null || mealType == null || recipe == null) {
        return _error('Invalid payload', 400);
      }
      final slot = {
        'id': (++_nextMealSlotId).toString(),
        'day_of_week': dayOfWeek,
        'meal_type': mealType,
        'is_flex': false,
        'flex_type': null,
        'is_completed': false,
        'servings': (data['servings'] as num?)?.toInt() ?? 2,
        'recipe': _toMealRecipeSummary(recipe),
      };
      (_mealPlan['slots'] as List).add(slot);
      return _ok(_copy(slot), 201);
    }

    if (method == 'POST' && path == '/api/recipes/generate') {
      return _ok(_generatedRecipePayload());
    }
    if (method == 'GET' && path == '/api/recipes') {
      final query = options.queryParameters;
      final q = query['q']?.toString().trim().toLowerCase() ?? '';
      final cuisine = query['cuisine']?.toString().trim().toLowerCase();
      final category = query['category']?.toString().trim().toLowerCase();
      final matchInventory =
          query['match_inventory'] == true ||
          query['match_inventory']?.toString() == 'true';

      final inventoryNames = _inventory
          .map(
            (i) => (i['ingredient_name'] ?? i['name']).toString().toLowerCase(),
          )
          .toSet();

      final filtered = _recipes
          .where((recipe) {
            if (q.isNotEmpty) {
              final name = recipe['name'].toString().toLowerCase();
              if (!name.contains(q)) return false;
            }
            if (cuisine != null && cuisine.isNotEmpty) {
              if (recipe['cuisine'].toString().toLowerCase() != cuisine) {
                return false;
              }
            }
            if (category != null && category.isNotEmpty) {
              if (recipe['category'].toString().toLowerCase() != category) {
                return false;
              }
            }
            if (matchInventory) {
              final ingredients = List<String>.from(
                recipe['ingredient_names'] as List<dynamic>,
              );
              final have = ingredients
                  .where((ing) => inventoryNames.contains(ing.toLowerCase()))
                  .length;
              final pct = (have / max(ingredients.length, 1)) * 100;
              if (pct < 40) return false;
            }
            return true;
          })
          .map(_toRecipeListItem)
          .toList();

      return _ok({'data': _copy(filtered)});
    }
    if (method == 'POST' && path == '/api/recipes') {
      final data = _asMap(options.data);
      final name = data['name']?.toString().trim();
      if (name == null || name.isEmpty) {
        return _error('Name is required', 400);
      }

      final ingredients = (data['ingredients'] as List<dynamic>? ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final instructions = (data['instructions'] as List<dynamic>? ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final recipe = _seedRecipe(
        id: ++_nextRecipeId,
        name: name,
        cuisine: 'Custom',
        category: 'Dinner',
        difficulty: data['difficulty']?.toString() ?? 'Easy',
        prep: (data['prep_time'] as num?)?.toInt() ?? 10,
        cook: (data['cook_time'] as num?)?.toInt() ?? 20,
        servings: 2,
        vegetarian: false,
        imageSeed: 'custom-$_nextRecipeId',
        ingredients: ingredients.isEmpty ? ['Ingredient'] : ingredients,
        steps: instructions.isEmpty ? ['Cook and enjoy.'] : instructions,
        macros: {'calories': 480, 'protein_g': 24, 'carbs_g': 45, 'fat_g': 18},
      );
      _recipes.insert(0, recipe);
      return _ok(_toRecipeDetail(recipe), 201);
    }
    if (segments.length == 3 &&
        method == 'GET' &&
        segments[0] == 'api' &&
        segments[1] == 'recipes') {
      final recipe = _findRecipe(segments[2]);
      if (recipe == null) return _error('Recipe not found', 404);
      return _ok(_toRecipeDetail(recipe));
    }

    if (method == 'GET' && path == '/api/browse/recipes') {
      final query = options.queryParameters;
      final q = query['q']?.toString().trim().toLowerCase() ?? '';
      final cuisine = query['cuisine']?.toString().trim().toLowerCase();
      final category = query['category']?.toString().trim().toLowerCase();
      final vegetarian =
          query['vegetarian'] == true ||
          query['vegetarian']?.toString() == 'true';
      final vegan =
          query['vegan'] == true || query['vegan']?.toString() == 'true';
      final glutenFree =
          query['gluten_free'] == true ||
          query['gluten_free']?.toString() == 'true';
      final maxTime = int.tryParse(query['max_time']?.toString() ?? '');
      final page = int.tryParse(query['page']?.toString() ?? '') ?? 1;
      final perPage = int.tryParse(query['per_page']?.toString() ?? '') ?? 20;

      final filtered = _recipes.where((recipe) {
        if (q.isNotEmpty &&
            !recipe['name'].toString().toLowerCase().contains(q)) {
          return false;
        }
        if (cuisine != null &&
            cuisine.isNotEmpty &&
            recipe['cuisine'].toString().toLowerCase() != cuisine) {
          return false;
        }
        if (category != null &&
            category.isNotEmpty &&
            recipe['category'].toString().toLowerCase() != category) {
          return false;
        }
        if (vegetarian && recipe['is_vegetarian'] != true) return false;
        if (vegan && recipe['is_vegan'] != true) return false;
        if (glutenFree && recipe['is_gluten_free'] != true) return false;
        if (maxTime != null &&
            ((recipe['total_time_min'] as int?) ?? 0) > maxTime) {
          return false;
        }
        return true;
      }).toList();

      final start = ((page - 1) * perPage).clamp(0, filtered.length);
      final end = min(start + perPage, filtered.length);
      final items = filtered
          .sublist(start, end)
          .map(_toBrowseListItem)
          .toList();
      return _ok({
        'recipes': _copy(items),
        'total': filtered.length,
        'page': page,
        'per_page': perPage,
      });
    }
    if (segments.length == 4 &&
        method == 'GET' &&
        segments[0] == 'api' &&
        segments[1] == 'browse' &&
        segments[2] == 'recipes') {
      final recipe = _findRecipe(segments[3]);
      if (recipe == null) return _error('Recipe not found', 404);
      return _ok(_toBrowseDetail(recipe));
    }


    if (method == 'GET' && path == '/api/inventory') {
      _refreshInventoryExpiry();
      return _ok({'items': _copy(_inventory)});
    }
    if (method == 'POST' && path == '/api/inventory/quick') {
      final created = _addInventoryItem(_asMap(options.data));
      if (created == null) return _error('Invalid inventory payload', 400);
      return _ok(_copy(created), 201);
    }
    if (segments.length == 3 &&
        method == 'PUT' &&
        segments[0] == 'api' &&
        segments[1] == 'inventory') {
      final id = segments[2];
      final item = _firstWhereOrNull(
        _inventory,
        (e) => e['id'].toString() == id,
      );
      if (item == null) return _error('Inventory item not found', 404);
      final data = _asMap(options.data);
      if (data.containsKey('quantity')) item['quantity'] = data['quantity'];
      if (data.containsKey('unit')) item['unit'] = data['unit'].toString();
      if (data.containsKey('storage_location')) {
        item['storage_location'] = data['storage_location'].toString();
      }
      if (data.containsKey('expiry_date')) {
        item['expiry_date'] = data['expiry_date']?.toString();
      }
      if (data.containsKey('name')) {
        final name = data['name'].toString();
        item['ingredient_name'] = name;
        item['name'] = name;
      }
      _refreshSingleInventoryExpiry(item);
      return _ok({'ok': true});
    }
    if (segments.length == 3 &&
        method == 'DELETE' &&
        segments[0] == 'api' &&
        segments[1] == 'inventory') {
      _inventory.removeWhere((e) => e['id'].toString() == segments[2]);
      return _ok({'ok': true});
    }
    if (method == 'GET' && path == '/api/inventory/expiring') {
      _refreshInventoryExpiry();
      final expiring = _inventory.where((item) {
        final days = (item['days_until_expiry'] as num?)?.toInt();
        return days != null && days >= 0 && days <= 3;
      }).toList();
      return _ok({'items': _copy(expiring)});
    }
    if (method == 'GET' && path == '/api/inventory/suggestions') {
      final inventoryNames = _inventory
          .map(
            (i) => (i['ingredient_name'] ?? i['name']).toString().toLowerCase(),
          )
          .toSet();
      final suggestions = _recipes
          .map((recipe) {
            final ingredientNames = List<String>.from(
              recipe['ingredient_names'] as List<dynamic>,
            );
            final have = ingredientNames
                .where((name) => inventoryNames.contains(name.toLowerCase()))
                .length;
            final total = max(ingredientNames.length, 1);
            return {
              'recipe_id': recipe['id'],
              'name': recipe['name'],
              'slug': recipe['slug'],
              'primary_image_url': recipe['primary_image_url'],
              'total_time_min': recipe['total_time_min'],
              'difficulty': recipe['difficulty'],
              'ingredients_have': have,
              'ingredients_total': total,
              'match_pct': ((have / total) * 100).round(),
            };
          })
          .where((s) => (s['match_pct'] as int) >= 40)
          .take(6)
          .toList();
      return _ok(_copy(suggestions));
    }
    if (method == 'POST' && path == '/api/inventory/scan') {
      return _ok({
        'items': [
          {
            'name': 'Spinach',
            'quantity': 1.0,
            'unit': 'bag',
            'category': 'vegetables',
            'storage_location': 'fridge',
          },
          {
            'name': 'Cherry tomatoes',
            'quantity': 300.0,
            'unit': 'g',
            'category': 'vegetables',
            'storage_location': 'fridge',
          },
          {
            'name': 'Feta cheese',
            'quantity': 200.0,
            'unit': 'g',
            'category': 'dairy',
            'storage_location': 'fridge',
          },
        ],
      });
    }
    if (method == 'POST' && path == '/api/inventory/bulk') {
      final items = options.data is List ? options.data as List : const [];
      final added = <Map<String, dynamic>>[];
      for (final raw in items) {
        final created = _addInventoryItem(
          Map<String, dynamic>.from(raw as Map),
        );
        if (created != null) added.add(created);
      }
      return _ok(_copy(added), 201);
    }

    if (method == 'GET' && path == '/api/ingredients') {
      final q =
          options.queryParameters['q']?.toString().trim().toLowerCase() ?? '';
      if (q.isEmpty) return _ok({'data': []});
      final pool = <String>{
        for (final recipe in _recipes)
          ...List<String>.from(recipe['ingredient_names'] as List<dynamic>),
        'Milk',
        'Rice',
        'Banana',
        'Paprika',
      }.toList()..sort((a, b) => a.compareTo(b));
      final filtered = pool
          .where((name) => name.toLowerCase().contains(q))
          .take(10)
          .toList();
      final data = List.generate(filtered.length, (index) {
        return {
          'id': index + 1,
          'name': filtered[index],
          'category': 'ingredient',
        };
      });
      return _ok({'data': data});
    }

    if (method == 'GET' && path == '/api/shopping-list') {
      return _ok({'items': _copy(_shopping)});
    }
    if (method == 'POST' && path == '/api/shopping-list/sync') {
      _syncShoppingFromPlan();
      return _ok({'ok': true});
    }
    if (method == 'POST' && path == '/api/shopping-list/items') {
      final data = _asMap(options.data);
      final name = data['name']?.toString().trim();
      if (name == null || name.isEmpty) return _error('Name is required', 400);
      final item = {
        'id': (++_nextShoppingId).toString(),
        'name': name,
        'quantity': (data['quantity'] as num?)?.toDouble() ?? 1.0,
        'unit': data['unit']?.toString() ?? 'pcs',
        'is_checked': false,
      };
      _shopping.insert(0, item);
      return _ok(_copy(item), 201);
    }
    if (segments.length == 5 &&
        method == 'PATCH' &&
        segments[0] == 'api' &&
        segments[1] == 'shopping-list' &&
        segments[2] == 'items' &&
        segments[4] == 'check') {
      final id = segments[3];
      final item = _firstWhereOrNull(
        _shopping,
        (e) => e['id'].toString() == id,
      );
      if (item == null) return _error('Shopping item not found', 404);
      final data = _asMap(options.data);
      final wasChecked = item['is_checked'] == true;
      final isChecked = data['is_checked'] == true;
      item['is_checked'] = isChecked;

      if (isChecked && !wasChecked) {
        final ingId = int.tryParse(item['ingredient_id']?.toString() ?? '') ?? 9999;
        final name = item['name']?.toString() ?? 'Unknown item';
        final qty = num.tryParse(item['quantity']?.toString() ?? '') ?? 1;
        final unit = item['unit']?.toString() ?? 'piece';

        final exists = _inventory.any((e) => e['ingredient_id'] == ingId || e['name'] == name);
        if (!exists) {
          _inventory.insert(
            0,
            _inventoryItem(
              id: (300 + _inventory.length + 1).toString(),
              ingredientId: ingId,
              name: name,
              quantity: qty,
              unit: unit,
              location: 'pantry',
              daysFromNow: 14,
            ),
          );
        }
      }
      return _ok({'ok': true});
    }
    if (segments.length == 4 &&
        method == 'DELETE' &&
        segments[0] == 'api' &&
        segments[1] == 'shopping-list' &&
        segments[2] == 'items') {
      _shopping.removeWhere((e) => e['id'].toString() == segments[3]);
      return _ok({'ok': true});
    }
    if (method == 'GET' && path == '/api/shopping-list/prices') {
      return _ok({
        'total_estimate': 38.4,
        'currency': 'EUR',
        'stores': [
          {'name': 'Continente', 'estimate': 39.1},
          {'name': 'Pingo Doce', 'estimate': 38.4},
          {'name': 'Lidl', 'estimate': 37.9},
        ],
      });
    }
    if (method == 'GET' && path == '/api/shopping-list/optimize') {
      return _ok({
        'route': ['Produce', 'Fridge', 'Pantry'],
        'estimated_savings': 4.2,
        'currency': 'EUR',
      });
    }

    if (method == 'POST' && path == '/api/chat') {
      final data = _asMap(options.data);
      final message = (data['message']?.toString() ?? '').trim();
      if (message.isEmpty) return _error('Message is required', 400);

      final providedSession = (data['session_id'] as num?)?.toInt();
      final sessionId = providedSession ?? _nextChatSessionId++;
      final turn = (_chatTurns[sessionId] ?? 0) + 1;
      _chatTurns[sessionId] = turn;

      final lower = message.toLowerCase();
      final actions = <String>[];
      var reply =
          "Got it. I can help with your meal plan, pantry, recipes, and groceries.";

      if (lower.contains('what can i cook') || lower.contains('cook today')) {
        actions.add('search_recipes');
        final top = _recipes.take(3).map((r) => r['name']).join(', ');
        reply = 'Based on your pantry, you could cook: $top.';
      } else if (lower.contains('meal plan')) {
        actions.add('get_meal_plan');
        reply =
            'Your weekly meal plan is ready. I can also swap any slot for you.';
      } else if (lower.contains('change dinner') || lower.contains('italian')) {
        final today = DateTime.now().weekday - 1;
        final slot = _firstWhereOrNull(
          (_mealPlan['slots'] as List<dynamic>).cast<Map<String, dynamic>>(),
          (s) => s['day_of_week'] == today && s['meal_type'] == 'dinner',
        );
        final italian = _recipes.firstWhere(
          (r) => r['cuisine'].toString().toLowerCase() == 'italian',
          orElse: () => _recipes.first,
        );
        if (slot != null) {
          slot['recipe'] = _toMealRecipeSummary(italian);
          slot['is_completed'] = false;
          actions.add('update_meal_plan_slot');
          reply = 'Done — dinner was updated to ${italian['name']}.';
        }
      } else if (lower.contains('mark') && lower.contains('done')) {
        final today = DateTime.now().weekday - 1;
        final slot = _firstWhereOrNull(
          (_mealPlan['slots'] as List<dynamic>).cast<Map<String, dynamic>>(),
          (s) => s['day_of_week'] == today && s['meal_type'] == 'dinner',
        );
        if (slot != null) {
          slot['is_completed'] = true;
          actions.add('mark_meal_completed');
          reply = 'Dinner marked as completed.';
        }
      } else if (lower.contains('expiring')) {
        _refreshInventoryExpiry();
        final expiring = _inventory.where((item) {
          final days = (item['days_until_expiry'] as num?)?.toInt();
          return days != null && days >= 0 && days <= 3;
        }).toList();
        actions.add('get_pantry');
        if (expiring.isEmpty) {
          reply = 'Good news — nothing is expiring in the next 3 days.';
        } else {
          final names = expiring
              .map((e) => (e['ingredient_name'] ?? e['name']).toString())
              .take(3)
              .join(', ');
          reply = 'These are expiring soon: $names.';
        }
      } else if (lower.contains('clear meal plan')) {
        for (final slot in (_mealPlan['slots'] as List<dynamic>)) {
          final item = slot as Map<String, dynamic>;
          item['recipe'] = null;
          item['is_completed'] = false;
          item['is_flex'] = false;
          item['flex_type'] = null;
        }
        actions.add('clear_meal_plan');
        reply = 'Your meal plan was cleared.';
      }

      return _ok({
        'session_id': sessionId,
        'message_id': _nextChatMessageId++,
        'reply': reply,
        'tokens_used': 120 + Random(sessionId + turn).nextInt(90),
        'actions_taken': actions,
      });
    }

    return null;
  }

  _MockResult _ok(dynamic data, [int statusCode = 200]) {
    return _MockResult(statusCode, data);
  }

  _MockResult _error(String message, [int statusCode = 400]) {
    return _MockResult(statusCode, {'error': message});
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  dynamic _copy(dynamic value) {
    return jsonDecode(jsonEncode(value));
  }

  Map<String, dynamic> _inventoryItem({
    required String id,
    required int ingredientId,
    required String name,
    required num quantity,
    required String unit,
    required String location,
    required int daysFromNow,
  }) {
    final expiry = DateTime.now().add(Duration(days: daysFromNow));
    return {
      'id': id,
      'ingredient_id': ingredientId,
      'ingredient_name': name,
      'name': name,
      'quantity': quantity.toDouble(),
      'unit': unit,
      'storage_location': location,
      'expiry_date': expiry.toIso8601String().split('T').first,
      'days_until_expiry': daysFromNow,
      'expiry_warning': daysFromNow <= 3,
    };
  }

  void _refreshInventoryExpiry() {
    for (final item in _inventory) {
      _refreshSingleInventoryExpiry(item);
    }
  }

  void _refreshSingleInventoryExpiry(Map<String, dynamic> item) {
    final expiryRaw = item['expiry_date']?.toString();
    if (expiryRaw == null || expiryRaw.isEmpty) {
      item['days_until_expiry'] = null;
      item['expiry_warning'] = false;
      return;
    }
    final expiry = DateTime.tryParse(expiryRaw);
    if (expiry == null) {
      item['days_until_expiry'] = null;
      item['expiry_warning'] = false;
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiry.year, expiry.month, expiry.day);
    final days = target.difference(today).inDays;
    item['days_until_expiry'] = days;
    item['expiry_warning'] = days >= 0 && days <= 3;
  }

  Map<String, dynamic>? _addInventoryItem(Map<String, dynamic> payload) {
    final name = payload['name']?.toString().trim();
    if (name == null || name.isEmpty) return null;
    final quantity = (payload['quantity'] as num?)?.toDouble() ?? 1.0;
    final unit = payload['unit']?.toString() ?? 'pcs';
    final location = payload['storage_location']?.toString() ?? 'pantry';
    final expiryDate = payload['expiry_date']?.toString();

    final item = {
      'id': (++_nextInventoryId).toString(),
      'ingredient_id': 9000 + _nextInventoryId,
      'ingredient_name': name,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'storage_location': location,
      'expiry_date': expiryDate,
      'days_until_expiry': null,
      'expiry_warning': false,
    };
    _refreshSingleInventoryExpiry(item);
    _inventory.insert(0, item);
    return item;
  }

  Map<String, dynamic>? _findRecipe(String id) {
    return _firstWhereOrNull(_recipes, (r) => r['id'].toString() == id);
  }

  Map<String, dynamic>? _findSlot(String slotId) {
    final slots = (_mealPlan['slots'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return _firstWhereOrNull(slots, (s) => s['id'].toString() == slotId);
  }

  Map<String, dynamic>? _firstWhereOrNull(
    Iterable<Map<String, dynamic>> items,
    bool Function(Map<String, dynamic>) test,
  ) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  Map<String, dynamic> _buildMealPlan({bool shuffle = false}) {
    final random = Random(42);
    final recipes = [..._recipes];
    if (shuffle) {
      recipes.shuffle(random);
    }

    final slots = <Map<String, dynamic>>[];
    var slotCounter = 1;
    const mealTypes = ['breakfast', 'lunch', 'dinner'];
    for (var day = 0; day < 7; day++) {
      for (var i = 0; i < mealTypes.length; i++) {
        final recipe = recipes[(day * mealTypes.length + i) % recipes.length];
        final slotId = slotCounter.toString();
        slotCounter += 1;
        slots.add({
          'id': slotId,
          'day_of_week': day,
          'meal_type': mealTypes[i],
          'is_flex': false,
          'flex_type': null,
          'is_completed': false,
          'servings': 2,
          'recipe': _toMealRecipeSummary(recipe),
        });
      }
    }
    _nextMealSlotId = max(_nextMealSlotId, slotCounter + 10);
    return {
      'id': '1',
      'slots': slots,
      'nutrition': {
        'calories_kcal': 2100,
        'protein_g': 138,
        'carbs_g': 220,
        'fat_g': 78,
      },
    };
  }

  Map<String, dynamic> _toMealRecipeSummary(Map<String, dynamic> recipe) {
    return {
      'id': recipe['id'],
      'name': recipe['name'],
      'cuisine': recipe['cuisine'],
      'total_time_min': recipe['total_time_min'],
      'difficulty': recipe['difficulty'],
    };
  }

  Map<String, dynamic> _toRecipeListItem(Map<String, dynamic> recipe) {
    return {
      'id': recipe['id'],
      'name': recipe['name'],
      'slug': recipe['slug'],
      'description': recipe['description'],
      'cuisine': recipe['cuisine'],
      'category': recipe['category'],
      'difficulty': recipe['difficulty'],
      'total_time_min': recipe['total_time_min'],
      'prep_time_min': recipe['prep_time_min'],
      'cook_time_min': recipe['cook_time_min'],
      'servings': recipe['servings'],
      'is_vegetarian': recipe['is_vegetarian'],
      'is_vegan': recipe['is_vegan'],
      'is_gluten_free': recipe['is_gluten_free'],
      'is_dairy_free': recipe['is_dairy_free'],
      'is_nut_free': recipe['is_nut_free'],
      'match_pct': recipe['match_pct'],
      'primary_image_url': recipe['primary_image_url'],
    };
  }

  Map<String, dynamic> _toRecipeDetail(Map<String, dynamic> recipe) {
    return {
      ..._toRecipeListItem(recipe),
      'images': _copy(recipe['images']),
      'ingredients': _copy(recipe['ingredients']),
      'steps': _copy(recipe['steps']),
      'nutrition': _copy(recipe['nutrition']),
      'source_url': recipe['source_url'],
    };
  }

  Map<String, dynamic> _toBrowseListItem(Map<String, dynamic> recipe) {
    return {
      'id': recipe['id'],
      'name': recipe['name'],
      'slug': recipe['slug'],
      'cuisine': recipe['cuisine'],
      'category': recipe['category'],
      'difficulty': recipe['difficulty'],
      'servings': recipe['servings'],
      'total_time_min': recipe['total_time_min'],
      'is_vegetarian': recipe['is_vegetarian'],
      'is_vegan': recipe['is_vegan'],
      'is_gluten_free': recipe['is_gluten_free'],
      'is_dairy_free': recipe['is_dairy_free'],
      'average_rating': 4.7,
      'rating_count': 120,
      'primary_image_url': recipe['primary_image_url'],
    };
  }

  Map<String, dynamic> _toBrowseDetail(Map<String, dynamic> recipe) {
    return {
      'id': recipe['id'],
      'name': recipe['name'],
      'slug': recipe['slug'],
      'description': recipe['description'],
      'cuisine': recipe['cuisine'],
      'category': recipe['category'],
      'difficulty': recipe['difficulty'],
      'servings': recipe['servings'],
      'prep_time_min': recipe['prep_time_min'],
      'cook_time_min': recipe['cook_time_min'],
      'total_time_min': recipe['total_time_min'],
      'is_vegetarian': recipe['is_vegetarian'],
      'is_vegan': recipe['is_vegan'],
      'is_gluten_free': recipe['is_gluten_free'],
      'is_dairy_free': recipe['is_dairy_free'],
      'is_nut_free': recipe['is_nut_free'],
      'source_url': recipe['source_url'],
      'average_rating': 4.7,
      'rating_count': 120,
      'ingredients': (recipe['ingredients'] as List<dynamic>).map((ing) {
        final map = Map<String, dynamic>.from(ing as Map);
        return {
          'name': map['ingredient_name'],
          'quantity': map['quantity'],
          'unit': map['unit'],
          'note': map['notes'],
        };
      }).toList(),
      'steps': (recipe['steps'] as List<dynamic>).map((step) {
        final map = Map<String, dynamic>.from(step as Map);
        return {
          'step_number': map['step_number'],
          'instruction': map['instruction'],
          'duration_min': map['duration_min'],
          'tip': map['tip'],
          'image_url': map['image_url'],
        };
      }).toList(),
      'images': _copy(recipe['images']),
      'nutrition': {
        'calories_kcal': recipe['nutrition']['calories'],
        'protein_g': recipe['nutrition']['protein_g'],
        'carbs_g': recipe['nutrition']['carbs_g'],
        'fat_g': recipe['nutrition']['fat_g'],
        'fiber_g': recipe['nutrition']['fiber_g'],
        'sugar_g': recipe['nutrition']['sugar_g'],
        'sodium_mg': recipe['nutrition']['sodium_mg'],
      },
    };
  }

  Map<String, dynamic> _seedRecipe({
    required int id,
    required String name,
    required String cuisine,
    required String category,
    required String difficulty,
    required int prep,
    required int cook,
    required int servings,
    required bool vegetarian,
    bool vegan = false,
    bool glutenFree = false,
    bool dairyFree = false,
    bool nutFree = false,
    required String imageSeed,
    required List<String> ingredients,
    required List<String> steps,
    required Map<String, num> macros,
    List<String> tags = const [],
  }) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final imageUrl = 'https://picsum.photos/seed/$imageSeed/1200/900';

    final ingredientMaps = List.generate(ingredients.length, (index) {
      return {
        'id': id * 100 + index + 1,
        'ingredient_id': id * 1000 + index + 1,
        'ingredient_name': ingredients[index],
        'quantity': (index + 1).toDouble(),
        'unit': index == 0 ? 'pcs' : 'g',
        'quantity_grams': 100.0 + (index * 25),
        'notes': null,
        'display_order': index + 1,
      };
    });

    final stepMaps = List.generate(steps.length, (index) {
      return {
        'id': id * 100 + 50 + index,
        'step_number': index + 1,
        'instruction': steps[index],
        'duration_min': 5 + index * 3,
        'image_url':
            'https://picsum.photos/seed/$imageSeed-step-$index/1000/700',
        'tip': index == 0 ? 'Prep everything before you start.' : null,
      };
    });

    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description':
          '$name is a demo recipe optimized for recording a polished Cookest walkthrough.',
      'cuisine': cuisine,
      'category': category,
      'difficulty': difficulty,
      'total_time_min': prep + cook,
      'prep_time_min': prep,
      'cook_time_min': cook,
      'servings': servings,
      'is_vegetarian': vegetarian,
      'is_vegan': vegan,
      'is_gluten_free': glutenFree,
      'is_dairy_free': dairyFree,
      'is_nut_free': nutFree,
      'match_pct': 82.0,
      'primary_image_url': imageUrl,
      'images': [
        {
          'id': id * 100 + 1,
          'url': imageUrl,
          'image_type': 'hero',
          'is_primary': true,
          'width': 1200,
          'height': 900,
        },
      ],
      'ingredients': ingredientMaps,
      'steps': stepMaps,
      'ingredient_names': ingredients,
      'nutrition': {
        'calories': macros['calories'],
        'protein_g': macros['protein_g'],
        'carbs_g': macros['carbs_g'],
        'fat_g': macros['fat_g'],
        'fiber_g': 8.0,
        'sugar_g': 7.0,
        'sodium_mg': 520.0,
        'saturated_fat_g': 4.0,
        'per_serving': true,
      },
      'source_url': 'https://demo.cookest.app/recipes/$slug',
      'tags': tags,
    };
  }

  Map<String, dynamic> _generatedRecipePayload() {
    return {
      'name': 'AI Lemon Herb Chicken',
      'description':
          'A quick high-protein meal built from your pantry and tuned for weekday dinners.',
      'cuisine': 'Mediterranean',
      'difficulty': 'Easy',
      'prep_minutes': 12,
      'cook_minutes': 18,
      'servings': 2,
      'ingredients': [
        {
          'name': 'Chicken breast',
          'quantity': 320.0,
          'unit': 'g',
          'is_pantry_item': true,
        },
        {
          'name': 'Olive oil',
          'quantity': 1.0,
          'unit': 'tbsp',
          'is_pantry_item': true,
        },
        {
          'name': 'Lemon',
          'quantity': 1.0,
          'unit': 'pcs',
          'is_pantry_item': false,
        },
        {
          'name': 'Garlic',
          'quantity': 2.0,
          'unit': 'cloves',
          'is_pantry_item': true,
        },
      ],
      'steps': [
        'Season chicken with salt, pepper, and minced garlic.',
        'Sear in olive oil for 4–5 minutes per side.',
        'Add lemon juice and rest before slicing.',
      ],
      'macros_per_serving': {
        'calories': 468.0,
        'protein_g': 44.0,
        'carbs_g': 8.0,
        'fat_g': 27.0,
        'fiber_g': 1.0,
      },
      'tags': ['high-protein', 'weeknight', 'pantry-friendly'],
      'score': {
        'overall': 8.9,
        'palatability': 9.1,
        'nutrition_balance': 8.4,
        'preference_match': 9.0,
        'palatability_reason': 'Bright lemon flavor with balanced richness.',
        'iterations': 2,
      },
    };
  }

  void _syncShoppingFromPlan() {
    final today = DateTime.now().weekday - 1;
    final slots = (_mealPlan['slots'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((s) => s['day_of_week'] == today);
    final needed = <String>{};
    for (final slot in slots) {
      final recipeId = slot['recipe']?['id']?.toString();
      final recipe = recipeId == null ? null : _findRecipe(recipeId);
      if (recipe == null) continue;
      final ingredientNames = List<String>.from(
        recipe['ingredient_names'] as List<dynamic>,
      );
      needed.addAll(ingredientNames.take(2));
    }

    final existing = _shopping
        .map((i) => i['name'].toString().toLowerCase())
        .toSet();
    for (final name in needed) {
      if (existing.contains(name.toLowerCase())) continue;
      _shopping.add({
        'id': (++_nextShoppingId).toString(),
        'name': name,
        'quantity': 1.0,
        'unit': 'pcs',
        'is_checked': false,
      });
    }
  }
}
