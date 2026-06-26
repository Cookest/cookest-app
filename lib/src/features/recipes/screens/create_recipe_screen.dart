import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import 'package:cookest/src/features/pantry/models/inventory_item.dart'
    show IngredientSuggestion;
import 'package:cookest/src/features/pantry/repositories/inventory_repository.dart';
import '../repositories/recipe_repository.dart';
import 'recipes_screen.dart';

const _recipeUnits = ['g', 'kg', 'ml', 'l', 'pcs', 'cup', 'tbsp', 'tsp', 'clove', 'pinch', 'can', 'pack'];

/// One ingredient row in the recipe builder — a catalog ingredient (id + name)
/// plus an optional quantity and unit.
class _RecipeIngredientEntry {
  final int id;
  final String name;
  final TextEditingController quantity;
  String unit;

  _RecipeIngredientEntry({required this.id, required this.name, String? unit})
      : quantity = TextEditingController(),
        unit = unit ?? 'g';
}

class CreateRecipeScreen extends ConsumerStatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  ConsumerState<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _difficulty = 'easy';
  final List<_RecipeIngredientEntry> _ingredients = [];
  bool _isLoading = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = picked);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _instructionsController.dispose();
    for (final e in _ingredients) {
      e.quantity.dispose();
    }
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final picked = await showIngredientPickerSheet(context, ref);
    if (picked == null) return;
    if (_ingredients.any((e) => e.id == picked.id)) return; // no duplicates
    setState(() {
      _ingredients.add(_RecipeIngredientEntry(id: picked.id, name: picked.name));
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Recipe name is required.');
      return;
    }

    final ingredients = _ingredients
        .map((e) => {
              'ingredient_id': e.id,
              'quantity': double.tryParse(e.quantity.text.trim()),
              'unit': e.unit,
            })
        .toList();

    final steps = _instructionsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) => {
          'step_number': e.key + 1,
          'instruction': e.value,
        })
        .toList();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recipe = await ref.read(recipeRepositoryProvider).createRecipe({
        'name': name,
        'description': _descriptionController.text.trim(),
        'prep_time_min': int.tryParse(_prepTimeController.text.trim()) ?? 0,
        'cook_time_min': int.tryParse(_cookTimeController.text.trim()) ?? 0,
        'difficulty': _difficulty,
        'ingredients': ingredients,
        'steps': steps,
      });

      if (_image != null) {
        await ref.read(recipeRepositoryProvider).uploadRecipeImage(recipe.id, _image!.path);
      }

      // refresh recipes
      ref.invalidate(communityRecipesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (e.toString().contains('Pro')) {
        if (mounted) context.push('/paywall');
      } else {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Recipe',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.appHeading,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              CkAlert(
                variant: CkAlertVariant.error,
                child: Text(_errorMessage!),
              ),
              const SizedBox(height: 16),
            ],
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appBorder),
                    image: _image != null
                        ? DecorationImage(
                            image: FileImage(File(_image!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.imagePlus,
                                size: 48, color: context.appMuted),
                            const SizedBox(height: 8),
                            Text('Add Recipe Image',
                                style: TextStyle(color: context.appMuted)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            CkInput(
              controller: _nameController,
              label: 'Recipe Name *',
              placeholder: 'e.g. Spaghetti Carbonara',
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            CkInput(
              controller: _descriptionController,
              label: 'Description',
              placeholder: 'Describe your recipe...',
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CkInput(
                    controller: _prepTimeController,
                    label: 'Prep Time (min)',
                    placeholder: '15',
                    keyboardType: TextInputType.number,
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CkInput(
                    controller: _cookTimeController,
                    label: 'Cook Time (min)',
                    placeholder: '30',
                    keyboardType: TextInputType.number,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CkSelect(
              label: 'Difficulty',
              placeholder: 'Select difficulty',
              options: [
                const CkSelectOption(value: 'easy', label: 'Easy'),
                const CkSelectOption(value: 'medium', label: 'Medium'),
                const CkSelectOption(value: 'hard', label: 'Hard'),
              ],
              value: _difficulty,
              onChanged: (val) => setState(() => _difficulty = val),
            ),
            const SizedBox(height: 16),
            Text(
              'Ingredients',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.appHeading,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick ingredients from the catalog so recipes stay consistent.',
              style: TextStyle(color: context.appMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Column(
              children: List.generate(_ingredients.length, (i) {
                final e = _ingredients[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          e.name,
                          style: TextStyle(
                            color: context.appHeading,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: CkInput(
                          controller: e.quantity,
                          placeholder: 'Qty',
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          fullWidth: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: CkSelect(
                          placeholder: 'Unit',
                          value: e.unit,
                          options: _recipeUnits
                              .map((u) => CkSelectOption(value: u, label: u))
                              .toList(),
                          onChanged: (val) => setState(() => e.unit = val),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 18),
                        onPressed: () {
                          setState(() {
                            e.quantity.dispose();
                            _ingredients.removeAt(i);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
            ),
            TextButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add ingredient'),
            ),
            const SizedBox(height: 16),
            CkTextarea(
              controller: _instructionsController,
              label: 'Instructions',
              placeholder: 'Step by step...',
              minLines: 5,
              maxLines: 12,
            ),
            const SizedBox(height: 24),
            CkButton(
              fullWidth: true,
              loading: _isLoading,
              onPressed: _submit,
              child: const Text('Create Recipe'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a catalog search sheet and returns the chosen ingredient (or null).
Future<IngredientSuggestion?> showIngredientPickerSheet(
    BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<IngredientSuggestion>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _IngredientPickerSheet(),
  );
}

class _IngredientPickerSheet extends ConsumerStatefulWidget {
  const _IngredientPickerSheet();

  @override
  ConsumerState<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends ConsumerState<_IngredientPickerSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<IngredientSuggestion> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      try {
        final results =
            await ref.read(inventoryRepositoryProvider).searchIngredients(q);
        if (mounted) setState(() => _results = results);
      } catch (_) {
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Find an ingredient',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 12),
          CkInput(
            controller: _controller,
            placeholder: 'Search the catalog...',
            fullWidth: true,
            iconLeft: const Icon(LucideIcons.search, size: 16),
            onChanged: _onChanged,
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CkProgress(size: CkProgressSize.sm, color: CkProgressColor.primary),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final s = _results[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(LucideIcons.leaf, size: 16, color: context.appMuted),
                    title: Text(s.name, style: TextStyle(color: context.appHeading)),
                    subtitle: s.category != null
                        ? Text(s.category!, style: TextStyle(color: context.appMuted, fontSize: 12))
                        : null,
                    onTap: () => Navigator.pop(context, s),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
