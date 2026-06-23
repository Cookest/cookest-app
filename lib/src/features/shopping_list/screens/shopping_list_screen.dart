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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _addItemController,
                onSubmitted: (_) => _addItem(),
                style: TextStyle(color: context.appHeading),
                decoration: InputDecoration(
                  hintText: 'Add an item...',
                  hintStyle: TextStyle(color: context.appMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.plusCircle, color: CookestTokens.colorPrimaryDEFAULT),
                    onPressed: _addItem,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    CkSkeletonCard(),
                    SizedBox(height: 12),
                    CkSkeletonCard(),
                    SizedBox(height: 12),
                    CkSkeletonCard(),
                  ],
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: CkAlert(
                  variant: CkAlertVariant.error,
                  child: Text('Failed to load shopping list: $e'),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.shoppingCart,
                              size: 48, color: CookestTokens.colorPrimaryDEFAULT),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Your list is empty',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: context.appHeading,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add items above or sync from your meal plan',
                          style: TextStyle(color: context.appMuted),
                        ),
                      ],
                    ),
                  );
                }

                final unchecked = items.where((i) => !i.isChecked).toList();
                final checked = items.where((i) => i.isChecked).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (unchecked.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text('To Buy', style: TextStyle(fontWeight: FontWeight.w600, color: context.appHeading)),
                      ),
                      ...unchecked.map((item) => _buildItemRow(item)),
                    ],
                    if (checked.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text('Completed', style: TextStyle(fontWeight: FontWeight.w600, color: context.appMuted)),
                      ),
                      ...checked.map((item) => _buildItemRow(item)),
                    ],
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(ShoppingItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: item.isChecked ? context.appBorder : Colors.transparent,
              width: 1,
            ),
            boxShadow: item.isChecked
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                try {
                  await ref.read(shoppingRepositoryProvider).toggleCheck(item.id, !item.isChecked);
                  ref.invalidate(shoppingListProvider);
                } catch (_) {}
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.isChecked ? CookestTokens.colorPrimaryDEFAULT : context.appBorder,
                          width: 2,
                        ),
                        color: item.isChecked ? CookestTokens.colorPrimaryDEFAULT : Colors.transparent,
                      ),
                      child: item.isChecked
                          ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: item.isChecked ? context.appMuted : context.appHeading,
                          decoration: item.isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
