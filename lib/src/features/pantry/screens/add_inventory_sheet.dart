import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';

// ── Common units ──────────────────────────────────────────────────────────────

const _units = ['pcs', 'g', 'kg', 'ml', 'l', 'pack', 'bottle', 'can', 'bag', 'box', 'tbsp', 'tsp', 'cup'];
const _locations = ['fridge', 'pantry', 'freezer'];

// ── Quick-add chips (popular items) ──────────────────────────────────────────

const _quickItems = [
  ('🥛', 'Milk', 1.0, 'l', 'fridge'),
  ('🥚', 'Eggs', 6.0, 'pcs', 'fridge'),
  ('🧀', 'Cheese', 200.0, 'g', 'fridge'),
  ('🍞', 'Bread', 1.0, 'pack', 'pantry'),
  ('🧅', 'Onion', 3.0, 'pcs', 'pantry'),
  ('🧄', 'Garlic', 1.0, 'pack', 'pantry'),
  ('🍅', 'Tomatoes', 4.0, 'pcs', 'fridge'),
  ('🫒', 'Olive Oil', 500.0, 'ml', 'pantry'),
  ('🍗', 'Chicken', 500.0, 'g', 'fridge'),
  ('🐟', 'Salmon', 300.0, 'g', 'fridge'),
  ('🥕', 'Carrots', 500.0, 'g', 'fridge'),
  ('🥔', 'Potatoes', 1.0, 'kg', 'pantry'),
];

/// Shows the add-ingredient bottom sheet.
/// Returns true if at least one item was added.
Future<bool> showAddInventorySheet(BuildContext context, WidgetRef ref) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const AddInventorySheet(),
  );
  return result == true;
}

class AddInventorySheet extends ConsumerStatefulWidget {
  const AddInventorySheet({super.key});

  @override
  ConsumerState<AddInventorySheet> createState() => _AddInventorySheetState();
}

class _AddInventorySheetState extends ConsumerState<AddInventorySheet> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _focusNode = FocusNode();

  String _selectedName = '';
  int? _selectedIngredientId;
  double _quantity = 1;
  String _unit = 'pcs';
  String _location = 'pantry';
  DateTime? _expiryDate;
  bool _saving = false;
  bool _added = false;

  List<IngredientSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    // Typing invalidates any previous catalog selection — the user must pick a
    // suggestion so the pantry only stores preset ingredients.
    setState(() {
      _selectedName = q;
      _selectedIngredientId = null;
    });
    if (q.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loadingSuggestions = true);
      try {
        final results =
            await ref.read(inventoryRepositoryProvider).searchIngredients(q);
        if (mounted) setState(() => _suggestions = results);
      } catch (_) {
      } finally {
        if (mounted) setState(() => _loadingSuggestions = false);
      }
    });
  }

  void _selectSuggestion(IngredientSuggestion s) {
    setState(() {
      _selectedName = s.name;
      _selectedIngredientId = s.id;
      _searchController.text = s.name;
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();
  }

  /// Quick chips are just names; resolve each against the catalog and select the
  /// matching preset ingredient (so we add by id, never free text).
  Future<void> _selectQuickItem((String, String, double, String, String) item) async {
    final (_, name, qty, unit, loc) = item;
    setState(() {
      _selectedName = name;
      _selectedIngredientId = null;
      _searchController.text = name;
      _quantity = qty;
      _quantityController.text =
          qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toString();
      _unit = unit;
      _location = loc;
      _suggestions = [];
      _loadingSuggestions = true;
    });
    try {
      final results =
          await ref.read(inventoryRepositoryProvider).searchIngredients(name);
      final lower = name.toLowerCase();
      IngredientSuggestion? match;
      for (final r in results) {
        if (r.name.toLowerCase() == lower) {
          match = r;
          break;
        }
      }
      final chosen = match ?? (results.isNotEmpty ? results.first : null);
      if (!mounted) return;
      if (chosen != null) {
        setState(() => _selectedIngredientId = chosen.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" is not in the catalog yet')),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _save() async {
    final name = _selectedName.trim();
    final ingredientId = _selectedIngredientId;
    if (name.isEmpty || ingredientId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(inventoryRepositoryProvider).addItemById({
        'ingredient_id': ingredientId,
        'quantity': _quantity,
        'unit': _unit,
        'storage_location': _location,
        if (_expiryDate != null)
          'expiry_date':
              _expiryDate!.toIso8601String().split('T').first,
      });
      ref.invalidate(inventoryListProvider);
      ref.invalidate(expiringCountProvider);
      ref.invalidate(recipeSuggestionsProvider);
      if (mounted) {
        setState(() {
          _added = true;
          _selectedName = '';
          _selectedIngredientId = null;
          _searchController.clear();
          _suggestions = [];
          _quantity = 1;
          _quantityController.text = '1';
          _unit = 'pcs';
          _location = 'pantry';
          _expiryDate = null;
        });
        _focusNode.requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added to pantry'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            // Title
            Text(
              'Add to Pantry',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.appHeading,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'What did you buy?',
              style: TextStyle(color: context.appMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Quick-add chips
            Text(
              'Quick add',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.appMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final item = _quickItems[i];
                  final selected = _selectedName == item.$2;
                  return GestureDetector(
                    onTap: () => _selectQuickItem(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? CookestTokens.colorPrimaryDEFAULT
                            : context.appSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? CookestTokens.colorPrimaryDEFAULT
                              : context.appBorder,
                        ),
                      ),
                      child: Text(
                        '${item.$1} ${item.$2}',
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? Colors.white : context.appHeading,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Search / name input
            CkInput(
              controller: _searchController,
              label: 'Ingredient name',
              placeholder: 'e.g. Chicken breast, Milk...',
              fullWidth: true,
              iconLeft: const Icon(LucideIcons.search, size: 16),
              onChanged: _onSearchChanged,
            ),

            // Autocomplete dropdown
            if (_loadingSuggestions)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: CkProgress(
                  size: CkProgressSize.sm,
                  color: CkProgressColor.primary,
                ),
              )
            else if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appBorder),
                ),
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(LucideIcons.leaf,
                          size: 16, color: context.appMuted),
                      title: Text(s.name,
                          style: TextStyle(
                              color: context.appHeading, fontSize: 14)),
                      subtitle: s.category != null
                          ? Text(s.category!,
                              style: TextStyle(
                                  color: context.appMuted, fontSize: 12))
                          : null,
                      onTap: () => _selectSuggestion(s),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Quantity + unit row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CkInput(
                    controller: _quantityController,
                    label: 'Quantity',
                    placeholder: '1',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    fullWidth: true,
                    onChanged: (v) {
                      setState(() =>
                          _quantity = double.tryParse(v) ?? 1.0);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: CkSelect(
                    label: 'Unit',
                    placeholder: 'Unit',
                    value: _unit,
                    options: _units
                        .map((u) => CkSelectOption(value: u, label: u))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Location
            CkSelect(
              label: 'Where to store',
              placeholder: 'Location',
              value: _location,
              options: _locations
                  .map((loc) => CkSelectOption(
                        value: loc,
                        label:
                            '${_locationLabel(loc)}  ${_locationEmoji(loc)}',
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _location = v),
            ),
            const SizedBox(height: 12),

            // Expiry date
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar,
                        size: 16,
                        color: _expiryDate != null
                            ? CookestTokens.colorPrimaryDEFAULT
                            : context.appMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _expiryDate == null
                            ? 'Set expiry date (optional)'
                            : 'Expires ${DateFormat.yMMMd().format(_expiryDate!)}',
                        style: TextStyle(
                          color: _expiryDate != null
                              ? context.appHeading
                              : context.appMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_expiryDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child: Icon(LucideIcons.x,
                            size: 14, color: context.appMuted),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hint when a name is typed but not yet picked from the catalog.
            if (_selectedName.trim().isNotEmpty &&
                _selectedIngredientId == null &&
                !_loadingSuggestions) ...[
              const SizedBox(height: 8),
              Text(
                'Pick an ingredient from the list to add it.',
                style: TextStyle(color: context.appMuted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),

            // Add button — enabled only once a catalog ingredient is selected.
            CkButton(
              onPressed:
                  _saving || _selectedIngredientId == null ? null : _save,
              loading: _saving,
              fullWidth: true,
              iconLeft: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
              child: Text(
                _selectedIngredientId == null
                    ? 'Add Item'
                    : 'Add ${_selectedName.trim()}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_added) ...[
              const SizedBox(height: 8),
              CkButton(
                variant: CkButtonVariant.ghost,
                size: CkButtonSize.sm,
                onPressed: () => Navigator.pop(context, true),
                iconLeft: Icon(LucideIcons.check, size: 14, color: context.appMuted),
                child: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _locationLabel(String loc) => switch (loc) {
      'fridge' => 'Fridge',
      'freezer' => 'Freezer',
      _ => 'Pantry',
    };

String _locationEmoji(String loc) => switch (loc) {
      'fridge' => '❄️',
      'freezer' => '🧊',
      _ => '🥫',
    };
