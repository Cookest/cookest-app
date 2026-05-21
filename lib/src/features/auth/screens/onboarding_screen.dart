import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../repositories/auth_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1 — Name
  String _name = '';

  // Step 2 — Cuisines
  final Set<String> _preferredCuisines = {};

  // Step 3 — Dietary restrictions
  final Set<String> _dietaryRestrictions = {};

  // Step 4 — Allergies
  final Set<String> _allergies = {};

  // Step 5 — Health goals
  final Set<String> _healthGoals = {};

  // Step 6 — Cooking profile
  String _cookingSkill = 'intermediate';
  double _householdSize = 2;
  double _weeklyBudget = 100;
  double _maxTimeMins = 30;
  double _mealFrequency = 7;

  // Step 7 — Taste calibration
  int _currentCalibrationIndex = 0;
  final List<Map<String, dynamic>> _likedCalibrationRecipes = [];

  static final List<Map<String, dynamic>> _calibrationRecipes = [
    {
      'id': 'c1',
      'name': 'Spaghetti Carbonara',
      'cuisine': 'Italian',
      'tags': ['pasta', 'creamy', 'quick'],
      'image': 'https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg',
    },
    {
      'id': 'c2',
      'name': 'Chicken Tikka Masala',
      'cuisine': 'Indian',
      'tags': ['curry', 'spicy', 'aromatic'],
      'image': 'https://www.themealdb.com/images/media/meals/wyxwsp1486979827.jpg',
    },
    {
      'id': 'c3',
      'name': 'Beef Tacos',
      'cuisine': 'Mexican',
      'tags': ['tacos', 'hearty', 'quick'],
      'image': 'https://www.themealdb.com/images/media/meals/typvxy1468572253.jpg',
    },
    {
      'id': 'c4',
      'name': 'Salmon Teriyaki',
      'cuisine': 'Japanese',
      'tags': ['fish', 'healthy', 'sweet'],
      'image': 'https://www.themealdb.com/images/media/meals/xxyupu1468262513.jpg',
    },
    {
      'id': 'c5',
      'name': 'Avocado Toast',
      'cuisine': 'American',
      'tags': ['breakfast', 'vegan', 'quick'],
      'image': 'https://www.themealdb.com/images/media/meals/xqusqy1487348868.jpg',
    },
    {
      'id': 'c6',
      'name': 'Shakshuka',
      'cuisine': 'Middle Eastern',
      'tags': ['eggs', 'vegetarian', 'spicy'],
      'image': 'https://www.themealdb.com/images/media/meals/g373701542403684.jpg',
    },
    {
      'id': 'c7',
      'name': 'Pad Thai',
      'cuisine': 'Thai',
      'tags': ['noodles', 'nutty', 'quick'],
      'image': 'https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg',
    },
    {
      'id': 'c8',
      'name': 'Greek Salad',
      'cuisine': 'Greek',
      'tags': ['salad', 'fresh', 'healthy'],
      'image': 'https://www.themealdb.com/images/media/meals/v3grxy1510743355.jpg',
    },
  ];

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).saveOnboarding({
        'name': _name.isNotEmpty ? _name : null,
        'dietary_restrictions': _dietaryRestrictions.toList(),
        'allergies': _allergies.toList(),
        'cooking_skill_level': _cookingSkill,
        'household_size': _householdSize.round(),
        'preferred_cuisines': _preferredCuisines.toList(),
        'health_goals': _healthGoals.toList(),
        'weekly_budget': _weeklyBudget,
        'preferred_time_per_meal_min': _maxTimeMins.round(),
        'meal_frequency': _mealFrequency.round(),
        'liked_recipe_ids':
            _likedCalibrationRecipes.map((r) => r['id']).toList(),
      });
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onCalibrationAction(bool liked) {
    if (_currentCalibrationIndex >= _calibrationRecipes.length) return;
    if (liked) {
      _likedCalibrationRecipes.add(
        Map<String, dynamic>.from(_calibrationRecipes[_currentCalibrationIndex]),
      );
    }
    setState(() => _currentCalibrationIndex++);
    if (_currentCalibrationIndex >= _calibrationRecipes.length) {
      _submit();
    }
  }

  Widget _buildChip(String label, String value, Set<String> selectedSet) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 14)),
      selected: selectedSet.contains(value),
      selectedColor: CookestTokens.colorPrimaryDEFAULT.withOpacity(0.2),
      checkmarkColor: CookestTokens.colorPrimaryDEFAULT,
      onSelected: (v) => setState(
        () => v ? selectedSet.add(value) : selectedSet.remove(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCalibration = _currentPage == 6;
    final calibrationDone = _currentCalibrationIndex >= 3 ||
        _currentCalibrationIndex >= _calibrationRecipes.length;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            CkProgress(
              value: (_currentPage + 1) / 7 * 100,
              color: CkProgressColor.primary,
              size: CkProgressSize.sm,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentPage + 1} of 7',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: context.appMuted),
                  ),
                  CkButton(
                    variant: CkButtonVariant.ghost,
                    size: CkButtonSize.sm,
                    onPressed: () => context.go('/'),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPage0(),
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPage4(),
                  _buildPage5(),
                  _buildPage6(),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: CkAlert(
                  variant: CkAlertVariant.error,
                  dismissible: true,
                  onDismiss: () => setState(() => _errorMessage = null),
                  child: Text(_errorMessage!),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    CkButton(
                      variant: CkButtonVariant.secondary,
                      onPressed: () => _goTo(_currentPage - 1),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (!isCalibration && _currentPage < 6)
                    CkButton(
                      onPressed: () => _goTo(_currentPage + 1),
                      child: const Text('Next'),
                    ),
                  if (isCalibration &&
                      calibrationDone &&
                      _currentCalibrationIndex < _calibrationRecipes.length)
                    CkButton(
                      onPressed: _submit,
                      loading: _isLoading,
                      child: const Text('Finish'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Welcome + Name ──────────────────────────────────────────────────

  Widget _buildPage0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Cookest 👋',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let's personalise your experience.",
            style: GoogleFonts.inter(fontSize: 16, color: context.appMuted),
          ),
          const SizedBox(height: 32),
          Text(
            'Your name',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appHeading),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => setState(() => _name = v),
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'What should we call you?',
              hintStyle: GoogleFonts.inter(color: context.appMuted),
              filled: true,
              fillColor: context.appSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Favourite cuisines ──────────────────────────────────────────────

  Widget _buildPage1() {
    const cuisines = {
      '🍕 Italian': 'italian',
      '🍜 Japanese': 'japanese',
      '🌮 Mexican': 'mexican',
      '🍛 Indian': 'indian',
      '🥙 Mediterranean': 'mediterranean',
      '🍲 Thai': 'thai',
      '🥐 French': 'french',
      '🍔 American': 'american',
      '🥘 Spanish': 'spanish',
      '🍱 Chinese': 'chinese',
      '🥗 Greek': 'greek',
      '🍗 Middle Eastern': 'middle_eastern',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What cuisines do you love?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick as many as you like',
            style: GoogleFonts.inter(fontSize: 14, color: context.appMuted),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cuisines.entries
                .map((e) => _buildChip(e.key, e.value, _preferredCuisines))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Dietary restrictions ───────────────────────────────────────────

  Widget _buildPage2() {
    const options = {
      'Vegetarian': 'vegetarian',
      'Vegan': 'vegan',
      'Gluten-free': 'gluten_free',
      'Dairy-free': 'dairy_free',
      'Keto': 'keto',
      'Paleo': 'paleo',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dietary preferences',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: GoogleFonts.inter(fontSize: 14, color: context.appMuted),
          ),
          const SizedBox(height: 24),
          ...options.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CkToggle(
                value: _dietaryRestrictions.contains(e.value),
                label: e.key,
                onChanged: (v) => setState(() => v
                    ? _dietaryRestrictions.add(e.value)
                    : _dietaryRestrictions.remove(e.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Allergies ──────────────────────────────────────────────────────

  Widget _buildPage3() {
    const allergens = {
      '🥜 Nuts': 'nuts',
      '🦐 Shellfish': 'shellfish',
      '🐟 Fish': 'fish',
      '🥚 Eggs': 'eggs',
      '🥛 Dairy': 'dairy',
      '🌾 Wheat/Gluten': 'wheat',
      '🫘 Soy': 'soy',
      '🌿 Sesame': 'sesame',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Any food allergies?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll keep these ingredients out of your recipes",
            style: GoogleFonts.inter(fontSize: 14, color: context.appMuted),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergens.entries
                .map((e) => _buildChip(e.key, e.value, _allergies))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Health goals ───────────────────────────────────────────────────

  Widget _buildPage4() {
    const goals = {
      '🔥 Lose weight': 'weight_loss',
      '💪 Build muscle': 'muscle_gain',
      '🌱 Eat more plants': 'plant_based',
      '⚡ High protein': 'high_protein',
      '🧘 Balanced diet': 'balanced',
      '❤️ Heart health': 'heart_health',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are your goals?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This shapes your meal recommendations',
            style: GoogleFonts.inter(fontSize: 14, color: context.appMuted),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goals.entries
                .map((e) => _buildChip(e.key, e.value, _healthGoals))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 6: Cooking profile ────────────────────────────────────────────────

  Widget _buildPage5() {
    const skills = ['Beginner', 'Intermediate', 'Advanced'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your kitchen habits',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Helps us tailor recipe complexity and portions',
            style: GoogleFonts.inter(fontSize: 14, color: context.appMuted),
          ),
          const SizedBox(height: 28),

          // Cooking level
          Text(
            'Cooking level',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appHeading),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: skills
                .map(
                  (s) => CkButton(
                    variant: _cookingSkill == s.toLowerCase()
                        ? CkButtonVariant.primary
                        : CkButtonVariant.secondary,
                    size: CkButtonSize.sm,
                    onPressed: () =>
                        setState(() => _cookingSkill = s.toLowerCase()),
                    child: Text(s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),

          // Household size
          Text(
            'Household size',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appHeading),
          ),
          const SizedBox(height: 8),
          CkSlider(
            value: _householdSize,
            min: 1,
            max: 8,
            step: 1,
            label: 'People',
            showValue: true,
            onChanged: (v) => setState(() => _householdSize = v),
          ),
          const SizedBox(height: 28),

          // Weekly budget
          Text(
            'Weekly budget',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appHeading),
          ),
          const SizedBox(height: 8),
          CkSlider(
            value: _weeklyBudget,
            min: 0,
            max: 500,
            step: 10,
            label: '€/week',
            showValue: true,
            onChanged: (v) => setState(() => _weeklyBudget = v),
          ),
          const SizedBox(height: 28),

          // Max time per meal
          Text(
            'Max time per meal',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appHeading),
          ),
          const SizedBox(height: 8),
          CkSlider(
            value: _maxTimeMins,
            min: 10,
            max: 120,
            step: 5,
            label: 'min',
            showValue: true,
            onChanged: (v) => setState(() => _maxTimeMins = v),
          ),
          const SizedBox(height: 28),

          // Meal frequency
          Text(
            'Meals cooked at home per week',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appHeading),
          ),
          const SizedBox(height: 8),
          CkSlider(
            value: _mealFrequency,
            min: 1,
            max: 21,
            step: 1,
            label: 'meals/week',
            showValue: true,
            onChanged: (v) => setState(() => _mealFrequency = v),
          ),
        ],
      ),
    );
  }

  // ── Step 7: Taste calibration ──────────────────────────────────────────────

  Widget _buildPage6() {
    final allDone = _currentCalibrationIndex >= _calibrationRecipes.length;

    if (allDone) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                'All done!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: context.appHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We've learned your style.\nTap Finish to start cooking.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 16, color: context.appMuted, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    final current = _calibrationRecipes[_currentCalibrationIndex];
    final hasNext = _currentCalibrationIndex + 1 < _calibrationRecipes.length;
    final next =
        hasNext ? _calibrationRecipes[_currentCalibrationIndex + 1] : null;
    final tags = (current['tags'] as List).cast<String>();
    final remaining = _calibrationRecipes.length - _currentCalibrationIndex;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Swipe to calibrate your taste',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Like or skip a few recipes — we'll learn your style",
            style: GoogleFonts.inter(fontSize: 14, color: context.appMuted),
          ),
          const SizedBox(height: 20),

          // Card stack
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (next != null)
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Transform.scale(
                      scale: 0.95,
                      child: _buildCalibrationCard(next, isBack: true),
                    ),
                  ),
                _buildCalibrationCard(current, isBack: false),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags
                .map(
                  (tag) => Chip(
                    label:
                        Text(tag, style: GoogleFonts.inter(fontSize: 12)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),

          // Love / Skip buttons
          Row(
            children: [
              Expanded(
                child: CkButton(
                  variant: CkButtonVariant.secondary,
                  onPressed: () => _onCalibrationAction(false),
                  child: const Text('❌  Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CkButton(
                  variant: CkButtonVariant.primary,
                  onPressed: () => _onCalibrationAction(true),
                  child: const Text('❤️  Love it'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Skip all + counter row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() =>
                      _currentCalibrationIndex = _calibrationRecipes.length);
                  _submit();
                },
                child: Text(
                  'Skip all',
                  style:
                      GoogleFonts.inter(fontSize: 13, color: context.appMuted),
                ),
              ),
              Text(
                '$remaining left',
                style: GoogleFonts.inter(fontSize: 12, color: context.appMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationCard(
    Map<String, dynamic> recipe, {
    required bool isBack,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: recipe['image'] as String,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: context.appSurface),
            errorWidget: (context, url, error) => Container(
              color: context.appSurface,
              child: Icon(Icons.restaurant, size: 48, color: context.appMuted),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.72),
                ],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          // Text overlay (front card only)
          if (!isBack)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe['name'] as String,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe['cuisine'] as String,
                    style:
                        GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
