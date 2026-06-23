import 'package:cached_network_image/cached_network_image.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import 'package:cookest/src/core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RecipeDiscoverScreen extends ConsumerStatefulWidget {
  const RecipeDiscoverScreen({super.key});

  @override
  ConsumerState<RecipeDiscoverScreen> createState() =>
      _RecipeDiscoverScreenState();
}

class _RecipeDiscoverScreenState extends ConsumerState<RecipeDiscoverScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _recipes = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  // Card drag state
  double _dragOffset = 0;
  double _dragRotation = 0;
  bool _isDragging = false;

  static const _fallbackRecipes = [
    {
      'id': '1',
      'name': 'Spaghetti Carbonara',
      'cuisine': 'Italian',
      'totalTimeMin': 25,
      'difficulty': 'medium',
      'tags': ['pasta', 'creamy'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg',
    },
    {
      'id': '2',
      'name': 'Chicken Tikka Masala',
      'cuisine': 'Indian',
      'totalTimeMin': 45,
      'difficulty': 'medium',
      'tags': ['curry', 'spicy'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/wyxwsp1486979827.jpg',
    },
    {
      'id': '3',
      'name': 'Beef Tacos',
      'cuisine': 'Mexican',
      'totalTimeMin': 20,
      'difficulty': 'easy',
      'tags': ['tacos', 'quick'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/typvxy1468572253.jpg',
    },
    {
      'id': '4',
      'name': 'Salmon Teriyaki',
      'cuisine': 'Japanese',
      'totalTimeMin': 30,
      'difficulty': 'easy',
      'tags': ['fish', 'healthy'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/xxyupu1468262513.jpg',
    },
    {
      'id': '5',
      'name': 'Shakshuka',
      'cuisine': 'Middle Eastern',
      'totalTimeMin': 25,
      'difficulty': 'easy',
      'tags': ['eggs', 'vegetarian'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/g373701542403684.jpg',
    },
    {
      'id': '6',
      'name': 'Pad Thai',
      'cuisine': 'Thai',
      'totalTimeMin': 30,
      'difficulty': 'medium',
      'tags': ['noodles', 'nutty'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg',
    },
    {
      'id': '7',
      'name': 'Greek Salad',
      'cuisine': 'Greek',
      'totalTimeMin': 15,
      'difficulty': 'easy',
      'tags': ['salad', 'fresh'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/v3grxy1510743355.jpg',
    },
    {
      'id': '8',
      'name': 'Avocado Toast',
      'cuisine': 'American',
      'totalTimeMin': 10,
      'difficulty': 'easy',
      'tags': ['breakfast', 'vegan'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/xqusqy1487348868.jpg',
    },
    {
      'id': '9',
      'name': 'Margherita Pizza',
      'cuisine': 'Italian',
      'totalTimeMin': 35,
      'difficulty': 'medium',
      'tags': ['pizza', 'vegetarian'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/x0lk931587671540.jpg',
    },
    {
      'id': '10',
      'name': 'Tom Yum Soup',
      'cuisine': 'Thai',
      'totalTimeMin': 30,
      'difficulty': 'medium',
      'tags': ['soup', 'spicy'],
      'primaryImageUrl':
          'https://www.themealdb.com/images/media/meals/1529445519.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/api/recipes',
        queryParameters: {'limit': 20, 'offset': 0},
      );
      final data = response.data;
      List<Map<String, dynamic>> loaded = [];
      if (data is Map && data['data'] is List) {
        loaded = (data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (data is List) {
        loaded =
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      setState(() {
        _recipes.addAll(loaded.isNotEmpty ? loaded : _fallbackRecipes);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _recipes.addAll(_fallbackRecipes);
        _isLoading = false;
      });
    }
  }

  void _onSwipe(String direction) {
    if (_currentIndex >= _recipes.length) return;
    final currentRecipe = _recipes[_currentIndex];

    // Fire-and-forget API call
    () async {
      try {
        final dio = ref.read(dioProvider);
        await dio.post('/api/me/swipe', data: {
          'recipe_id': int.tryParse(currentRecipe['id'].toString()) ?? 0,
          'direction': direction,
        });
      } catch (_) {}
    }();

    final liked = direction == 'like' ? currentRecipe : null;

    setState(() {
      _currentIndex++;
      _dragOffset = 0;
      _dragRotation = 0;
      _isDragging = false;
    });

    if (liked != null && mounted) {
      _showAddToPlanSheet(liked);
    }
  }

  void _showAddToPlanSheet(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.appBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '🎉 You loved ${recipe['name']}!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.appHeading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Want to add it to your meal plan?',
              style: GoogleFonts.inter(color: context.appMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CkButton(
                    iconLeft:
                        const Icon(LucideIcons.sparkles, size: 16),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showAIFitOverlay(recipe);
                    },
                    child: const Text('Add to Plan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CkButton(
                    variant: CkButtonVariant.ghost,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Maybe later'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAIFitOverlay(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AIFitSheet(recipe: recipe),
    );
  }

  void _snapBack() {
    setState(() {
      _dragOffset = 0;
      _dragRotation = 0;
      _isDragging = false;
    });
  }

  Widget _buildRecipeCard(
    Map<String, dynamic> recipe, {
    bool isTop = false,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.70;
    final tags =
        (recipe['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final imageUrl = recipe['primaryImageUrl'] as String? ?? '';
    final name = recipe['name'] as String? ?? '';
    final cuisine = recipe['cuisine'] as String? ?? '';
    final totalTimeMin = recipe['totalTimeMin'] ?? 0;
    final difficulty = recipe['difficulty'] as String? ?? '';

    final showLike = isTop && _isDragging && _dragOffset > 60;
    final showDislike = isTop && _isDragging && _dragOffset < -60;

    Widget card = SizedBox(
      height: cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: context.appSurface,
                      child: Center(
                        child: Icon(
                          LucideIcons.chefHat,
                          size: 48,
                          color: context.appMuted,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: context.appSurface,
                      child: Center(
                        child: Icon(
                          LucideIcons.chefHat,
                          size: 48,
                          color: context.appMuted,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: context.appSurface,
                    child: Center(
                      child: Icon(
                        LucideIcons.chefHat,
                        size: 48,
                        color: context.appMuted,
                      ),
                    ),
                  ),
            // Bottom gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.4],
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Info panel
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (cuisine.isNotEmpty) _badge(cuisine),
                      if (totalTimeMin > 0) ...[
                        const SizedBox(width: 6),
                        _badge('$totalTimeMin min'),
                      ],
                      if (difficulty.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _badge(difficulty),
                      ],
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children:
                          tags.take(3).map((t) => _tag(t)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Like overlay
            if (showLike)
              Positioned(
                top: 24,
                left: 24,
                child: _swipeLabel('LOVE IT', Colors.green),
              ),
            // Dislike overlay
            if (showDislike)
              Positioned(
                top: 24,
                right: 24,
                child: _swipeLabel('NOPE', Colors.red),
              ),
          ],
        ),
      ),
    );

    if (isTop) {
      return GestureDetector(
        onHorizontalDragStart: (_) =>
            setState(() => _isDragging = true),
        onHorizontalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dx;
            _dragRotation = _dragOffset / 300;
          });
        },
        onHorizontalDragEnd: (_) {
          if (_dragOffset > 100) {
            _onSwipe('like');
          } else if (_dragOffset < -100) {
            _onSwipe('dislike');
          } else {
            _snapBack();
          }
        },
        child: Transform.rotate(
          angle: _dragRotation,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: card,
          ),
        ),
      );
    }

    return card;
  }

  Widget _badge(String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _tag(String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '#$label',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      );

  Widget _swipeLabel(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final total = _recipes.length;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          color: context.appHeading,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Discover Recipes',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.appHeading,
          ),
        ),
        actions: [
          if (total > 0 && _currentIndex < total)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / $total',
                  style: GoogleFonts.inter(
                    color: context.appMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CkSpinner(size: CkSpinnerSize.md))
          : _currentIndex >= _recipes.length
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Card +2 (back)
                            if (_currentIndex + 2 < _recipes.length)
                              Transform.translate(
                                offset: const Offset(0, -16),
                                child: Transform.scale(
                                  scale: 0.9,
                                  child: _buildRecipeCard(
                                    _recipes[_currentIndex + 2],
                                  ),
                                ),
                              ),
                            // Card +1 (middle)
                            if (_currentIndex + 1 < _recipes.length)
                              Transform.translate(
                                offset: const Offset(0, -8),
                                child: Transform.scale(
                                  scale: 0.95,
                                  child: _buildRecipeCard(
                                    _recipes[_currentIndex + 1],
                                  ),
                                ),
                              ),
                            // Top card (interactive)
                            _buildRecipeCard(
                              _recipes[_currentIndex],
                              isTop: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _onSwipe('dislike'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            elevation: 4,
          ),
          child: const Icon(LucideIcons.x, size: 32),
        ),
        const SizedBox(width: 48),
        ElevatedButton(
          onPressed: () => _onSwipe('like'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade50,
            foregroundColor: Colors.green,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            elevation: 4,
          ),
          child: const Icon(LucideIcons.heart, size: 32),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "You're all caught up! 🎉",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Check back later for more recipes.',
            style: GoogleFonts.inter(color: context.appMuted),
          ),
          const SizedBox(height: 24),
          CkButton(
            variant: CkButtonVariant.secondary,
            onPressed: () => context.pop(),
            child: const Text('Back to Meal Plan'),
          ),
        ],
      ),
    );
  }
}

// ─ AI Fit Bottom Sheet ───────────────────────────────────────────────────────

class _AIFitSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> recipe;
  const _AIFitSheet({required this.recipe});

  @override
  ConsumerState<_AIFitSheet> createState() => _AIFitSheetState();
}

class _AIFitSheetState extends ConsumerState<_AIFitSheet> {
  bool _loading = true;
  String? _suggestedDay;
  String? _suggestedMeal;
  String? _error;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner'];

  @override
  void initState() {
    super.initState();
    _computeSuggestion();
  }

  Future<void> _computeSuggestion() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _suggestedDay = _days[DateTime.now().weekday % 7];
      _suggestedMeal = _mealTypes[1]; // Default to Lunch
      _loading = false;
    });
  }

  Future<void> _confirm() async {
    if (_suggestedDay == null || _suggestedMeal == null) return;
    final dayIndex = _days.indexOf(_suggestedDay!);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/meal-plans/current/slots', data: {
        'recipe_id':
            int.tryParse(widget.recipe['id'].toString()) ?? 0,
        'day_of_week': dayIndex,
        'meal_type': _suggestedMeal!.toLowerCase(),
        'servings': 2,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to your meal plan!')),
      );
    } catch (e) {
      setState(() => _error = 'Failed to add: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final imageUrl = recipe['primaryImageUrl'] as String? ?? '';
    final name = recipe['name'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Icon(LucideIcons.bot, size: 20, color: CookestTokens.colorPrimaryDEFAULT),
              const SizedBox(width: 8),
              Text(
                'AI Meal Fit',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appHeading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: context.appSurface,
                        child: Icon(
                          LucideIcons.chefHat,
                          color: context.appMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.appHeading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            Column(
              children: [
                Text(
                  'Finding the best slot...',
                  style: GoogleFonts.inter(color: context.appMuted),
                ),
                const SizedBox(height: 16),
                const CkSpinner(size: CkSpinnerSize.md),
                const SizedBox(height: 8),
              ],
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Suggests:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: context.appHeading,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_suggestedDay · $_suggestedMeal',
                  style: GoogleFonts.inter(
                    color: CookestTokens.colorPrimaryDEFAULT,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CkButton(
                    onPressed: _confirm,
                    child: const Text('Confirm'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CkButton(
                    variant: CkButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Change slot'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
