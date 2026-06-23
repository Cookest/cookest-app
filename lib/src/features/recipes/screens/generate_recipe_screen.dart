import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../models/generated_recipe.dart';
import '../repositories/recipe_gen_repository.dart';

// ── Option lists ──────────────────────────────────────────────────────────────

const _cuisines = [
  CkSelectOption(value: 'Portuguesa', label: 'Portuguesa'),
  CkSelectOption(value: 'Italiana', label: 'Italiana'),
  CkSelectOption(value: 'Espanhola', label: 'Espanhola'),
  CkSelectOption(value: 'Francesa', label: 'Francesa'),
  CkSelectOption(value: 'Mediterrânea', label: 'Mediterrânea'),
  CkSelectOption(value: 'Asiática', label: 'Asiática'),
  CkSelectOption(value: 'Mexicana', label: 'Mexicana'),
  CkSelectOption(value: 'Indiana', label: 'Indiana'),
  CkSelectOption(value: 'Americana', label: 'Americana'),
];

const _timeOptions = [
  CkSelectOption(value: '20', label: '20 min'),
  CkSelectOption(value: '30', label: '30 min'),
  CkSelectOption(value: '45', label: '45 min'),
  CkSelectOption(value: '60', label: '1 hora'),
  CkSelectOption(value: '90', label: '1h 30min'),
  CkSelectOption(value: '120', label: '2 horas'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class GenerateRecipeScreen extends ConsumerStatefulWidget {
  const GenerateRecipeScreen({super.key});

  @override
  ConsumerState<GenerateRecipeScreen> createState() =>
      _GenerateRecipeScreenState();
}

class _GenerateRecipeScreenState extends ConsumerState<GenerateRecipeScreen>
    with SingleTickerProviderStateMixin {
  bool _usePantry = true;
  String? _selectedCuisine;
  String? _selectedMaxMinutes;

  late final AnimationController _spinAnim;
  int _loadingPhase = 0;

  static const _loadingMessages = [
    'A pensar numa ideia deliciosa…',
    'A combinar ingredientes…',
    'A calcular a nutrição…',
    'A avaliar o sabor…',
    'A refinar a receita…',
    'Quase pronto…',
  ];

  @override
  void initState() {
    super.initState();
    _spinAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _spinAnim.dispose();
    super.dispose();
  }

  void _generate() {
    setState(() => _loadingPhase = 0);
    _advanceLoadingMessage();
    ref.read(recipeGenProvider.notifier).generate(
          usePantry: _usePantry,
          cuisineHint: _selectedCuisine,
          maxMinutes: _selectedMaxMinutes != null
              ? int.tryParse(_selectedMaxMinutes!)
              : null,
        );
  }

  void _advanceLoadingMessage() {
    Future.delayed(const Duration(seconds: 9), () {
      if (!mounted) return;
      if (ref.read(recipeGenProvider) is RecipeGenLoading) {
        setState(
            () => _loadingPhase = (_loadingPhase + 1) % _loadingMessages.length);
        _advanceLoadingMessage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeGenProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(recipeGenProvider.notifier).reset();
            Navigator.of(context).pop();
          },
          child: Icon(LucideIcons.arrowLeft, size: 20, color: context.appHeading),
        ),
        title: Text(
          'Gerar Receita com IA',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: context.appHeading,
          ),
        ),
      ),
      body: switch (state) {
        RecipeGenIdle() || RecipeGenError() => _buildForm(context, state),
        RecipeGenLoading() => _buildLoading(context),
        RecipeGenSuccess(:final recipe) => _buildResult(context, recipe),
      },
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context, RecipeGenState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A IA vai criar uma receita personalizada para ti, avaliando e refinando o resultado até ficares com algo delicioso.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.appMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Pantry toggle
          _label(context, 'Ingredientes'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CkButton(
                  variant: _usePantry
                      ? CkButtonVariant.primary
                      : CkButtonVariant.secondary,
                  iconLeft: const Icon(LucideIcons.package, size: 14),
                  onPressed: () => setState(() => _usePantry = true),
                  child: const Text('Da despensa'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CkButton(
                  variant: !_usePantry
                      ? CkButtonVariant.primary
                      : CkButtonVariant.secondary,
                  iconLeft: const Icon(LucideIcons.globe, size: 14),
                  onPressed: () => setState(() => _usePantry = false),
                  child: const Text('Qualquer coisa'),
                ),
              ),
            ],
          ),
          if (_usePantry) ...[
            const SizedBox(height: 6),
            Text(
              'Usará os ingredientes que tens na despensa como base.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: context.appMuted),
            ),
          ],
          const SizedBox(height: 24),

          // Cuisine
          _label(context, 'Tipo de cozinha (opcional)'),
          const SizedBox(height: 8),
          CkSelect(
            placeholder: 'Qualquer cozinha',
            value: _selectedCuisine,
            options: _cuisines,
            onChanged: (v) => setState(() => _selectedCuisine = v),
          ),
          const SizedBox(height: 20),

          // Max time
          _label(context, 'Tempo máximo (opcional)'),
          const SizedBox(height: 8),
          CkSelect(
            placeholder: 'Sem limite de tempo',
            value: _selectedMaxMinutes,
            options: _timeOptions,
            onChanged: (v) => setState(() => _selectedMaxMinutes = v),
          ),
          const SizedBox(height: 32),

          // Error banner
          if (state is RecipeGenError) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle,
                      size: 16, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.message,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFD32F2F)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Generate CTA
          CkButton(
            iconLeft: const Icon(LucideIcons.sparkles, size: 16),
            fullWidth: true,
            size: CkButtonSize.lg,
            onPressed: _generate,
            child: const Text('Gerar Receita'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Pode demorar até 2 minutos — a IA pensa sério!',
              style: GoogleFonts.inter(
                  fontSize: 12, color: context.appMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _spinAnim,
              builder: (context2, _) => Transform.rotate(
                angle: _spinAnim.value * 2 * math.pi,
                child: Icon(LucideIcons.chefHat,
                    size: 48, color: CookestTokens.colorPrimaryDEFAULT),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _loadingMessages[_loadingPhase],
                key: ValueKey(_loadingPhase),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appHeading,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A IA está a criar e avaliar a tua receita…',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: context.appMuted),
            ),
            const SizedBox(height: 32),
            const CkProgress(
              size: CkProgressSize.sm,
              color: CkProgressColor.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────

  Widget _buildResult(BuildContext context, GeneratedRecipe recipe) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RecipeHeaderCard(recipe: recipe),
          const SizedBox(height: 16),
          _ScoreCard(score: recipe.score),
          const SizedBox(height: 16),
          _MacrosRow(macros: recipe.macrosPerServing),
          const SizedBox(height: 16),
          _label(context, 'Ingredientes'),
          const SizedBox(height: 8),
          ...recipe.ingredients.map((ing) => _IngredientRow(ing: ing)),
          const SizedBox(height: 16),
          _label(context, 'Preparação'),
          const SizedBox(height: 8),
          ...recipe.steps.asMap().entries.map(
                (e) => _StepRow(index: e.key + 1, text: e.value),
              ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CkButton(
                  variant: CkButtonVariant.secondary,
                  iconLeft: const Icon(LucideIcons.x, size: 14),
                  onPressed: () =>
                      ref.read(recipeGenProvider.notifier).reset(),
                  child: const Text('Descartar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CkButton(
                  variant: CkButtonVariant.secondary,
                  iconLeft:
                      const Icon(LucideIcons.refreshCw, size: 14),
                  onPressed: _generate,
                  child: const Text('Tentar outra'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CkButton(
            iconLeft: const Icon(LucideIcons.bookmarkPlus, size: 16),
            fullWidth: true,
            size: CkButtonSize.lg,
            onPressed: () => _saveRecipe(recipe),
            child: const Text('Guardar receita'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.appMuted,
          letterSpacing: 0.4,
        ),
      );

  void _saveRecipe(GeneratedRecipe recipe) {
    // TODO: wire to a save-to-my-recipes endpoint once created
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${recipe.name} guardada nas tuas receitas!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }
}

// ── Recipe header card ────────────────────────────────────────────────────────

class _RecipeHeaderCard extends StatelessWidget {
  const _RecipeHeaderCard({required this.recipe});
  final GeneratedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  recipe.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.appHeading,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _DifficultyBadge(difficulty: recipe.difficulty),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            recipe.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.appMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MetaChip(
                  icon: LucideIcons.clock,
                  label: '${recipe.totalMinutes} min'),
              _MetaChip(
                  icon: LucideIcons.users,
                  label: '${recipe.servings} pessoas'),
              _MetaChip(
                  icon: LucideIcons.globe2, label: recipe.cuisine),
            ],
          ),
          if (recipe.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recipe.tags.map((t) => _Tag(label: t)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.appMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12, color: context.appMuted),
          ),
        ],
      );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CookestTokens.colorPrimaryDEFAULT,
          ),
        ),
      );
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final String difficulty;

  Color get _color => switch (difficulty) {
        'beginner' => Colors.green.shade600,
        'intermediate' => Colors.orange.shade600,
        'advanced' => Colors.red.shade600,
        _ => Colors.grey,
      };

  String get _label => switch (difficulty) {
        'beginner' => 'Fácil',
        'intermediate' => 'Médio',
        'advanced' => 'Difícil',
        _ => difficulty,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      );
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final RecipeScore score;

  static Color _scoreColor(double v) {
    if (v >= 8.0) return Colors.green.shade600;
    if (v >= 6.0) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final overall = _scoreColor(score.overall);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles,
                  size: 14, color: CookestTokens.colorPrimaryDEFAULT),
              const SizedBox(width: 6),
              Text(
                'Avaliação da IA',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.appHeading,
                ),
              ),
              const Spacer(),
              Text(
                score.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: overall,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${score.overall.toStringAsFixed(1)}/10',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: overall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '"${score.palatabilityReason}"',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: context.appMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _ScoreDimension(
              label: 'Sabor',
              icon: LucideIcons.heart,
              value: score.palatability),
          const SizedBox(height: 8),
          _ScoreDimension(
              label: 'Nutrição',
              icon: LucideIcons.leaf,
              value: score.nutritionBalance),
          const SizedBox(height: 8),
          _ScoreDimension(
              label: 'Preferências',
              icon: LucideIcons.userCheck,
              value: score.preferenceMatch),
          if (score.iterations > 1) ...[
            const SizedBox(height: 12),
            const CkDivider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.refreshCw,
                    size: 12, color: context.appMuted),
                const SizedBox(width: 4),
                Text(
                  'Refinada ${score.iterations} ${score.iterations == 1 ? 'vez' : 'vezes'} pela IA',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: context.appMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreDimension extends StatelessWidget {
  const _ScoreDimension({
    required this.label,
    required this.icon,
    required this.value,
  });
  final String label;
  final IconData icon;
  final double value;

  Color get _color {
    if (value >= 8.0) return Colors.green.shade600;
    if (value >= 6.0) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: _color),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: context.appMuted),
            ),
          ),
          Expanded(
            child: CkProgress(
              value: value / 10.0,
              size: CkProgressSize.sm,
              color: CkProgressColor.primary,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ),
        ],
      );
}

// ── Macros ────────────────────────────────────────────────────────────────────

class _MacrosRow extends StatelessWidget {
  const _MacrosRow({required this.macros});
  final GenMacros macros;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrição por dose',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.appMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroCell(
                label: 'Calorias',
                value: macros.calories.toStringAsFixed(0),
                unit: 'kcal',
              ),
              _MacroCell(
                label: 'Proteína',
                value: macros.proteinG.toStringAsFixed(1),
                unit: 'g',
              ),
              _MacroCell(
                label: 'Hidratos',
                value: macros.carbsG.toStringAsFixed(1),
                unit: 'g',
              ),
              _MacroCell(
                label: 'Gordura',
                value: macros.fatG.toStringAsFixed(1),
                unit: 'g',
              ),
              _MacroCell(
                label: 'Fibra',
                value: macros.fiberG.toStringAsFixed(1),
                unit: 'g',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({
    required this.label,
    required this.value,
    required this.unit,
  });
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.appHeading,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: CookestTokens.colorPrimaryDEFAULT,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10, color: context.appMuted),
          ),
        ],
      );
}

// ── Ingredients ───────────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ing});
  final GenIngredient ing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(
              ing.isPantryItem
                  ? LucideIcons.package
                  : LucideIcons.shoppingCart,
              size: 14,
              color: ing.isPantryItem
                  ? CookestTokens.colorPrimaryDEFAULT
                  : context.appMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ing.name,
                style: GoogleFonts.inter(
                    fontSize: 14, color: context.appHeading),
              ),
            ),
            Text(
              '${ing.quantity % 1 == 0 ? ing.quantity.toInt() : ing.quantity} ${ing.unit}',
              style: GoogleFonts.inter(
                  fontSize: 13, color: context.appMuted),
            ),
          ],
        ),
      );
}

// ── Steps ─────────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: CookestTokens.colorPrimaryDEFAULT,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.appHeading,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
}
