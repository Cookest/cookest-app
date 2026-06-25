import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../../pantry/repositories/inventory_repository.dart';

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

  // Step 7 — Pantry quick-setup
  // Selected staple names (keys of [_pantryStaples]). Tap to toggle.
  final Set<String> _selectedPantry = {};

  /// Common pantry staples shown as tap-to-toggle tiles for a fast setup.
  /// Tuple: (emoji, name, quantity, unit, storageLocation).
  static const List<(String, String, double, String, String)> _pantryStaples = [
    ('🥛', 'Milk', 1.0, 'l', 'fridge'),
    ('🥚', 'Eggs', 6.0, 'pcs', 'fridge'),
    ('🧀', 'Cheese', 200.0, 'g', 'fridge'),
    ('🧈', 'Butter', 250.0, 'g', 'fridge'),
    ('🍞', 'Bread', 1.0, 'pack', 'pantry'),
    ('🍚', 'Rice', 1.0, 'kg', 'pantry'),
    ('🍝', 'Pasta', 500.0, 'g', 'pantry'),
    ('🧅', 'Onion', 3.0, 'pcs', 'pantry'),
    ('🧄', 'Garlic', 1.0, 'pack', 'pantry'),
    ('🍅', 'Tomatoes', 4.0, 'pcs', 'fridge'),
    ('🥔', 'Potatoes', 1.0, 'kg', 'pantry'),
    ('🥕', 'Carrots', 500.0, 'g', 'fridge'),
    ('🫑', 'Peppers', 3.0, 'pcs', 'fridge'),
    ('🥬', 'Salad', 1.0, 'pack', 'fridge'),
    ('🍗', 'Chicken', 500.0, 'g', 'fridge'),
    ('🥩', 'Beef', 500.0, 'g', 'fridge'),
    ('🐟', 'Fish', 300.0, 'g', 'fridge'),
    ('🫒', 'Olive Oil', 500.0, 'ml', 'pantry'),
    ('🧂', 'Salt', 1.0, 'pack', 'pantry'),
    ('🫘', 'Beans', 400.0, 'g', 'pantry'),
    ('🥫', 'Canned Tomatoes', 2.0, 'can', 'pantry'),
    ('🧇', 'Flour', 1.0, 'kg', 'pantry'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
      });

      // Seed the pantry with the staples the user selected (best-effort —
      // a failure here must not block finishing onboarding).
      if (_selectedPantry.isNotEmpty) {
        final items = _pantryStaples
            .where((s) => _selectedPantry.contains(s.$2))
            .map((s) => {
                  'name': s.$2,
                  'quantity': s.$3,
                  'unit': s.$4,
                  'storage_location': s.$5,
                })
            .toList();
        try {
          await ref.read(inventoryRepositoryProvider).bulkAdd(items);
        } catch (_) {
          // ignore — pantry can be filled later from the Pantry tab
        }
      }

      if (mounted) {
        ref.read(authProvider.notifier).markOnboardingCompleted();
        context.go('/');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goTo(int page) {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildChip(String label, String value, Set<String> selectedSet) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: context.appHeading,
        ),
      ),
      selected: selectedSet.contains(value),
      selectedColor: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.2),
      checkmarkColor: CookestTokens.colorPrimaryDEFAULT,
      onSelected: (v) => setState(
        () => v ? selectedSet.add(value) : selectedSet.remove(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentPage == 6;

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
                  if (!isLastStep)
                    CkButton(
                      onPressed: () => _goTo(_currentPage + 1),
                      child: const Text('Next'),
                    ),
                  if (isLastStep)
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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
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
        ],
      ),
    );
  }

  // ── Step 7: Pantry quick-setup ─────────────────────────────────────────────

  Widget _buildPage6() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's in your kitchen?",
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the staples you already have — we use this to suggest meals '
            'and build smarter shopping lists. You can refine it anytime.',
            style: GoogleFonts.inter(
                fontSize: 14, color: context.appMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                _pantryStaples.map((s) => _buildPantryTile(s)).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedPantry.isEmpty
                ? 'Nothing selected — that\'s OK, you can add items later.'
                : '${_selectedPantry.length} item${_selectedPantry.length == 1 ? '' : 's'} selected',
            style: GoogleFonts.inter(fontSize: 13, color: context.appMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryTile((String, String, double, String, String) staple) {
    final name = staple.$2;
    final selected = _selectedPantry.contains(name);
    return GestureDetector(
      onTap: () => setState(() => selected
          ? _selectedPantry.remove(name)
          : _selectedPantry.add(name)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.15)
              : context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? CookestTokens.colorPrimaryDEFAULT
                : context.appBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(staple.$1, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected
                    ? CookestTokens.colorPrimaryDEFAULT
                    : context.appHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
