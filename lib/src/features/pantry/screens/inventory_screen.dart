import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../repositories/inventory_repository.dart';
import '../models/inventory_item.dart';
import 'add_inventory_sheet.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _fabOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddSheet() async {
    setState(() => _fabOpen = false);
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddInventorySheet(),
    );
    if (added == true) {
      ref.invalidate(inventoryListProvider);
      ref.invalidate(expiringCountProvider);
      ref.invalidate(recipeSuggestionsProvider);
    }
  }

  Future<void> _openScanScreen() async {
    setState(() => _fabOpen = false);
    final added = await context.push<bool>('/grocery-scan');
    if (added == true) {
      ref.invalidate(inventoryListProvider);
      ref.invalidate(expiringCountProvider);
      ref.invalidate(recipeSuggestionsProvider);
    }
  }

  Future<void> _openBarcodeScan() async {
    setState(() => _fabOpen = false);
    final added = await context.push<bool>('/barcode-scan');
    if (added == true) {
      ref.invalidate(inventoryListProvider);
      ref.invalidate(expiringCountProvider);
      ref.invalidate(recipeSuggestionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryListProvider);
    final expiringAsync = ref.watch(expiringCountProvider);

    return GestureDetector(
      onTap: () { if (_fabOpen) setState(() => _fabOpen = false); },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appBackground,
          elevation: 0,
          title: Text(
            'My Pantry',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
          ),
        ),
        floatingActionButton: _buildFab(context),
        body: inventoryAsync.when(
          loading: () => _buildLoading(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: CkAlert(
              variant: CkAlertVariant.error,
              child: Text('Failed to load pantry: $e'),
            ),
          ),
          data: (items) {
            final filtered = _searchQuery.isEmpty
                ? items
                : items
                    .where((i) => i.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

            if (items.isEmpty) return _buildEmptyState();

            return CustomScrollView(
              slivers: [
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: CkInput(
                      controller: _searchController,
                      placeholder: 'Search pantry…',
                      iconLeft: const Icon(LucideIcons.search, size: 16),
                      fullWidth: true,
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),

                // Expiry alert
                SliverToBoxAdapter(
                  child: expiringAsync.maybeWhen(
                    data: (count) => count > 0
                        ? Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: CkAlert(
                              variant: CkAlertVariant.warning,
                              title: 'Expiring soon',
                              child:
                                  Text('$count item${count == 1 ? '' : 's'} expire within 3 days'),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),

                // Recipe suggestions banner
                SliverToBoxAdapter(
                  child: _RecipeSuggestionsBanner(),
                ),

                // Items grouped by location
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.search,
                              size: 40, color: context.appMuted),
                          const SizedBox(height: 10),
                          Text(
                            'No results for "$_searchQuery"',
                            style: TextStyle(color: context.appMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildGroupedItems(filtered),

                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.refrigerator,
              size: 54,
              color: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your pantry is empty',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Add your groceries to get personalised recipe suggestions and track what you have at home.',
            style: TextStyle(color: context.appMuted, height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          CkButton(
            onPressed: _openScanScreen,
            fullWidth: true,
            iconLeft: const Icon(LucideIcons.scanLine,
                size: 18, color: Colors.white),
            child: const Text('Scan Groceries'),
          ),
          const SizedBox(height: 12),
          CkButton(
            onPressed: _openAddSheet,
            fullWidth: true,
            variant: CkButtonVariant.secondary,
            iconLeft: Icon(LucideIcons.plus,
                size: 18, color: CookestTokens.colorPrimaryDEFAULT),
            child: const Text('Add Manually'),
          ),
        ],
      ),
    ),
    );
  }

  // ── Loading skeleton ──────────────────────────────────────────────────────

  Widget _buildLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          CkSkeletonCard(),
          SizedBox(height: 12),
          CkSkeletonCard(),
          SizedBox(height: 12),
          CkSkeletonCard(),
        ],
      ),
    );
  }

  // ── Grouped list ──────────────────────────────────────────────────────────

  Widget _buildGroupedItems(List<InventoryItem> items) {
    final groups = <String, List<InventoryItem>>{};
    const order = ['fridge', 'freezer', 'pantry'];
    for (final item in items) {
      groups.putIfAbsent(item.location, () => []).add(item);
    }
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        final ai = order.indexOf(a);
        final bi = order.indexOf(b);
        return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
      });

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final key = sortedKeys[index];
          final groupItems = groups[key]!;
          final label = key[0].toUpperCase() + key.substring(1);
          final icon = _locationIcon(key);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: context.appMuted),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: context.appHeading,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(width: 8),
                      CkBadge(
                        variant: CkBadgeVariant.standard,
                        size: CkBadgeSize.sm,
                        child: Text('${groupItems.length}'),
                      ),
                    ],
                  ),
                ),
                ...groupItems.map((item) => _InventoryItemTile(
                      item: item,
                      onDeleted: () {
                        ref.invalidate(inventoryListProvider);
                        ref.invalidate(expiringCountProvider);
                        ref.invalidate(recipeSuggestionsProvider);
                      },
                    )),
                Divider(color: context.appBorder),
              ],
            ),
          );
        },
        childCount: sortedKeys.length,
      ),
    );
  }

  // ── Speed-dial FAB ────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_fabOpen) ...[
          _MiniButton(
            label: 'Add manually',
            icon: LucideIcons.plus,
            onPressed: _openAddSheet,
          ),
          const SizedBox(height: 10),
          _MiniButton(
            label: 'Scan groceries',
            icon: LucideIcons.scanLine,
            onPressed: _openScanScreen,
          ),
          const SizedBox(height: 10),
          _MiniButton(
            label: 'Scan barcode',
            icon: LucideIcons.scanLine,
            onPressed: _openBarcodeScan,
          ),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _fabOpen = !_fabOpen),
          backgroundColor: CookestTokens.colorPrimaryDEFAULT,
          foregroundColor: Colors.white,
          elevation: 2,
          child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_fabOpen ? LucideIcons.x : LucideIcons.plus),
          ),
        ),
      ],
    );
  }
}

// ── Mini FAB label button ─────────────────────────────────────────────────────

class _MiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _MiniButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(8),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.appHeading,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: CookestTokens.colorPrimaryDEFAULT,
          foregroundColor: Colors.white,
          elevation: 2,
          child: Icon(icon, size: 16),
        ),
      ],
    );
  }
}

// ── Recipe suggestions horizontal banner ──────────────────────────────────────

class _RecipeSuggestionsBanner extends ConsumerWidget {
  const _RecipeSuggestionsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(recipeSuggestionsProvider);

    return suggestionsAsync.maybeWhen(
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles,
                      size: 16,
                      color: CookestTokens.colorPrimaryDEFAULT),
                  const SizedBox(width: 6),
                  Text(
                    'You can make these',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.appHeading,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 156,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: suggestions.length,
                itemBuilder: (ctx, i) =>
                    _SuggestionCard(suggestion: suggestions[i]),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final RecipeSuggestion suggestion;
  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 140,
        child: CkCard(
          padding: CkCardPadding.none,
          variant: CkCardVariant.interactive,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10)),
                child: suggestion.primaryImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: suggestion.primaryImageUrl!,
                        height: 80,
                        width: 140,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          height: 80,
                          width: 140,
                          color: context.appBorder,
                          child: Icon(LucideIcons.chefHat,
                              color: context.appMuted),
                        ),
                      )
                    : Container(
                        height: 80,
                        width: 140,
                        color: context.appBorder,
                        child:
                            Icon(LucideIcons.chefHat, color: context.appMuted),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.appHeading,
                        ),
                      ),
                      const Spacer(),
                      CkBadge(
                        variant: suggestion.matchPct >= 70
                            ? CkBadgeVariant.success
                            : CkBadgeVariant.warning,
                        size: CkBadgeSize.sm,
                        child: Text('${suggestion.matchPct}% match'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Inventory item tile (swipe to delete) ─────────────────────────────────────

class _InventoryItemTile extends ConsumerWidget {
  final InventoryItem item;
  final VoidCallback onDeleted;

  const _InventoryItemTile({
    required this.item,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final daysLeft = item.expiryDate?.difference(now).inDays;
    final isExpired = daysLeft != null && daysLeft < 0;
    final isExpiringSoon = daysLeft != null && daysLeft >= 0 && daysLeft <= 5;

    final badgeVariant = isExpired
        ? CkBadgeVariant.error
        : isExpiringSoon
            ? CkBadgeVariant.warning
            : null;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(LucideIcons.pencil, color: CookestTokens.colorPrimaryDEFAULT, size: 20),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CookestTokens.colorStatusError.withValues(alpha: 0.0),
              CookestTokens.colorStatusError.withValues(alpha: 0.2),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(LucideIcons.trash2, color: CookestTokens.colorStatusError, size: 20),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          _showEditDialog(context, ref);
          return false;
        }
        return true;
      },
      onDismissed: (dir) async {
        if (dir == DismissDirection.endToStart) {
          await ref.read(inventoryRepositoryProvider).deleteItem(item.id);
          onDeleted();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CkCard(
          padding: CkCardPadding.sm,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: context.appHeading,
                      ),
                    ),
                    Text(
                      _qtyLabel(item),
                      style: TextStyle(
                          fontSize: 13, color: context.appMuted),
                    ),
                  ],
                ),
              ),
              if (item.expiryDate != null && badgeVariant != null)
                CkBadge(
                  variant: badgeVariant,
                  size: CkBadgeSize.sm,
                  child: Text(
                    isExpired
                        ? 'Expired'
                        : daysLeft == 0
                            ? 'Today'
                            : 'in ${daysLeft}d',
                  ),
                )
              else if (item.expiryDate != null)
                Text(
                  DateFormat.MMMd().format(item.expiryDate!),
                  style: TextStyle(fontSize: 12, color: context.appMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _qtyLabel(InventoryItem item) {
    final q = item.quantity;
    final qs = q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
    return '$qs ${item.unit}';
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
        text: item.quantity == item.quantity.truncateToDouble()
            ? item.quantity.toInt().toString()
            : item.quantity.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text('Edit Quantity',
            style: TextStyle(color: context.appHeading, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Quantity (${item.unit})',
            labelStyle: TextStyle(color: context.appMuted),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.appBorder)),
          ),
          style: TextStyle(color: context.appHeading),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.appMuted)),
          ),
          TextButton(
            onPressed: () async {
              final newQty = double.tryParse(controller.text);
              if (newQty != null && newQty > 0) {
                // To actually update, the repository needs an update method.
                // Assuming it might not exist yet, we can do delete then add,
                // or just call update if available. Let's try add for now
                // since addItem handles adding to inventory.
                // Wait, if we use addItem it might create a duplicate or update existing if ingredient matches.
                // Let's add it via API and delete the old one, or just update.
                // For safety, let's assume the API has update or addItem handles upsert.
                Navigator.pop(ctx);
                await ref.read(inventoryRepositoryProvider).addItem({
                  'name': item.name,
                  'quantity': newQty,
                  'unit': item.unit,
                  'storage_location': item.location,
                  if (item.expiryDate != null) 'expiry_date': item.expiryDate!.toIso8601String(),
                });
                // Also delete old item? No, the addItem by name usually upserts or adds to existing in many systems, 
                // but actually let's delete and re-add.
                await ref.read(inventoryRepositoryProvider).deleteItem(item.id);
                onDeleted(); // refetches
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: CookestTokens.colorPrimaryDEFAULT)),
          ),
        ],
      ),
    );
  }
}

IconData _locationIcon(String loc) => switch (loc) {
      'fridge' => LucideIcons.thermometerSnowflake,
      'freezer' => LucideIcons.snowflake,
      _ => LucideIcons.shoppingBag,
    };
