import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../repositories/shopping_repository.dart';
import '../models/shopping_item.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() =>
      _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _addItemController = TextEditingController();

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    try {
      await ref.read(shoppingRepositoryProvider).syncFromPlan();
      ref.invalidate(shoppingListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error syncing: $e')));
      }
    }
  }

  Future<void> _addItem() async {
    final text = _addItemController.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(shoppingRepositoryProvider).addItem(text, 1, 'pcs');
      _addItemController.clear();
      ref.invalidate(shoppingListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error adding: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: Text(
          'Groceries',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.appHeading,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'What to buy',
            icon: const Icon(LucideIcons.sparkles, size: 18),
            color: CookestTokens.colorPrimaryDEFAULT,
            onPressed: () => context.push('/what-to-buy'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CkButton(
              variant: CkButtonVariant.ghost,
              size: CkButtonSize.sm,
              iconLeft: const Icon(LucideIcons.refreshCcw, size: 16),
              onPressed: _sync,
              child: const Text('Sync'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Column(
              children: [
                CkInput(
                  controller: _addItemController,
                  placeholder: 'Add item...',
                  fullWidth: true,
                  onSubmitted: (_) => _addItem(),
                ),
                const SizedBox(height: 8),
                CkButton(
                  fullWidth: true,
                  onPressed: _addItem,
                  child: const Text('Add to Groceries'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: listAsync.when(
                loading: () => const Column(
                  children: [
                    CkSkeletonCard(),
                    SizedBox(height: 12),
                    CkSkeletonCard(),
                    SizedBox(height: 12),
                    CkSkeletonCard(),
                  ],
                ),
                error: (e, _) => CkAlert(
                  variant: CkAlertVariant.error,
                  child: Text('Failed to load shopping list: $e'),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.shoppingCart,
                              size: 48, color: context.appMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Your shopping list is empty',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: context.appHeading),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add items or sync from your meal plan',
                            style: TextStyle(
                                color: context.appMuted),
                          ),
                          const SizedBox(height: 8),
                          CkButton(
                            size: CkButtonSize.sm,
                            onPressed: _sync,
                            child: const Text('Sync from Meal Plan'),
                          ),
                        ],
                      ),
                    );
                  }

                  final sorted = [...items]..sort((a, b) {
                      if (a.isChecked == b.isChecked) return 0;
                      return a.isChecked ? 1 : -1;
                    });

                  return ListView.builder(
                    itemCount: sorted.length,
                    itemBuilder: (context, index) =>
                        _buildItemRow(sorted[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(ShoppingItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: CookestTokens.colorStatusError,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 18),
      ),
      onDismissed: (_) async {
        await ref.read(shoppingRepositoryProvider).deleteItem(item.id);
        ref.invalidate(shoppingListProvider);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CkCard(
          padding: CkCardPadding.sm,
          child: CkToggle(
            value: item.isChecked,
            label: item.name,
            onChanged: (val) async {
              try {
                await ref
                    .read(shoppingRepositoryProvider)
                    .toggleCheck(item.id, val);
                ref.invalidate(shoppingListProvider);
              } catch (_) {}
            },
          ),
        ),
      ),
    );
  }
}
