import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../repositories/recipe_repository.dart';
import 'recipes_screen.dart';

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
  final List<TextEditingController> _ingredientControllers = [TextEditingController()];
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
    for (final c in _ingredientControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Recipe name is required.');
      return;
    }

    final ingredients = _ingredientControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => {
          'ingredient_name': s,
          'quantity': null,
          'unit': null,
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
      ref.invalidate(recipesListProvider);
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
            const SizedBox(height: 8),
            Column(
              children: List.generate(_ingredientControllers.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: CkInput(
                          controller: _ingredientControllers[i],
                          placeholder: 'e.g. 2 cups flour',
                          fullWidth: true,
                        ),
                      ),
                      if (_ingredientControllers.length > 1)
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 18),
                          onPressed: () {
                            setState(() {
                              _ingredientControllers[i].dispose();
                              _ingredientControllers.removeAt(i);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _ingredientControllers.add(TextEditingController());
                });
              },
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
