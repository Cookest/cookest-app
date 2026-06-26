import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';

const _scanUnits = [
  'pcs', 'g', 'kg', 'ml', 'l',
  'pack', 'bottle', 'can', 'bag', 'box'
];
const _scanLocations = ['fridge', 'pantry', 'freezer'];

enum _Phase { picker, scanning, review, error }

class GroceryScanScreen extends ConsumerStatefulWidget {
  const GroceryScanScreen({super.key});

  @override
  ConsumerState<GroceryScanScreen> createState() => _GroceryScanScreenState();
}

class _GroceryScanScreenState extends ConsumerState<GroceryScanScreen> {
  _Phase _phase = _Phase.picker;
  List<DetectedGroceryItem> _items = [];
  String? _errorMessage;
  bool _saving = false;
  File? _previewFile;

  int get _selectedCount => _items.where((i) => i.selected).length;

  Future<void> _pickAndScan(ImageSource source) async {
    XFile? xFile;
    try {
      xFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
    } catch (e) {
      _setError('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e');
      return;
    }

    if (xFile == null) return;

    setState(() {
      _previewFile = File(xFile!.path);
      _phase = _Phase.scanning;
      _errorMessage = null;
    });

    try {
      final bytes = await xFile.readAsBytes();
      final detected = await ref.read(inventoryRepositoryProvider).scanImage(bytes);
      if (!mounted) return;

      if (detected.isEmpty) {
        _setError('No items detected. Try a clearer photo with items spread out and good lighting.');
      } else {
        setState(() {
          _items = detected;
          _phase = _Phase.review;
        });
      }
    } catch (e) {
      if (e.toString().contains('Pro')) {
        if (mounted) context.push('/paywall');
      } else {
        _setError('Scan failed: $e');
      }
    }
  }

  void _setError(String msg) {
    if (mounted) setState(() { _errorMessage = msg; _phase = _Phase.error; });
  }

  Future<void> _confirmAdd() async {
    final toAdd = _items.where((i) => i.selected).toList();
    if (toAdd.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(inventoryRepositoryProvider).bulkAdd(
        toAdd.map((i) => i.toJson()).toList(),
      );
      ref.invalidate(inventoryListProvider);
      ref.invalidate(expiringCountProvider);
      ref.invalidate(recipeSuggestionsProvider);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add items: $e')),
        );
        setState(() => _saving = false);
      }
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
          icon: Icon(LucideIcons.arrowLeft, color: context.appHeading),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Scan Groceries',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.appHeading,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _phase == _Phase.review
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CkButton(
                onPressed: (_saving || _selectedCount == 0) ? null : _confirmAdd,
                loading: _saving,
                fullWidth: true,
                iconLeft: const Icon(LucideIcons.shoppingBag,
                    size: 16, color: Colors.white),
                child: Text(
                  _selectedCount == 0
                      ? 'Select items to add'
                      : 'Add $_selectedCount item${_selectedCount == 1 ? '' : 's'} to Pantry',
                ),
              ),
            )
          : null,
      body: switch (_phase) {
        _Phase.picker  => _buildPicker(),
        _Phase.scanning => _buildScanning(),
        _Phase.review  => _buildReview(),
        _Phase.error   => _buildError(),
      },
    );
  }

  // ── Picker ──────────────────────────────────────────────────────────────────

  Widget _buildPicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.scanLine,
              size: 64,
              color: CookestTokens.colorPrimaryDEFAULT,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Scan your groceries',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.appHeading,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Take a photo of your groceries and AI will identify them '
            'and add them to your pantry automatically.',
            style: TextStyle(color: context.appMuted, height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          CkButton(
            onPressed: () => _pickAndScan(ImageSource.camera),
            fullWidth: true,
            iconLeft: const Icon(LucideIcons.camera, size: 18, color: Colors.white),
            child: const Text('Take a Photo'),
          ),
          const SizedBox(height: 12),
          CkButton(
            onPressed: () => _pickAndScan(ImageSource.gallery),
            fullWidth: true,
            variant: CkButtonVariant.secondary,
            iconLeft: Icon(LucideIcons.image,
                size: 18, color: CookestTokens.colorPrimaryDEFAULT),
            child: const Text('Choose from Gallery'),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Icon(LucideIcons.info, size: 14, color: context.appMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tip: spread items on a flat surface with good lighting for best results.',
                  style: TextStyle(color: context.appMuted, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Scanning ─────────────────────────────────────────────────────────────────

  Widget _buildScanning() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_previewFile != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _previewFile!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
        const CkSpinner(size: CkSpinnerSize.sm),
        const SizedBox(height: 20),
        Text(
          'Analysing your groceries…',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.appHeading,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This may take up to 30 seconds',
          style: TextStyle(color: context.appMuted),
        ),
      ],
    );
  }

  // ── Review ───────────────────────────────────────────────────────────────────

  Widget _buildReview() {
    final allSelected = _items.isNotEmpty && _items.every((i) => i.selected);

    return Column(
      children: [
        if (_previewFile != null)
          SizedBox(
            height: 90,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_previewFile!, fit: BoxFit.cover),
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles,
                          size: 16, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(width: 8),
                      Text(
                        'Found ${_items.length} item${_items.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Review and edit detected items',
                  style: TextStyle(color: context.appMuted, fontSize: 13),
                ),
              ),
              CkButton(
                variant: CkButtonVariant.ghost,
                size: CkButtonSize.sm,
                onPressed: () => setState(() {
                  for (final item in _items) {
                    item.selected = !allSelected;
                  }
                }),
                child: Text(
                  allSelected ? 'Deselect all' : 'Select all',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            itemCount: _items.length,
            itemBuilder: (ctx, i) => _DetectedItemTile(item: _items[i]),
          ),
        ),
      ],
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle,
              size: 56, color: CookestTokens.colorStatusError),
          const SizedBox(height: 16),
          Text(
            'Scan failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.appHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Something went wrong. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMuted, height: 1.5),
          ),
          const SizedBox(height: 32),
          CkButton(
            onPressed: () => setState(() => _phase = _Phase.picker),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

// ── Detected item tile ────────────────────────────────────────────────────────

class _DetectedItemTile extends StatefulWidget {
  final DetectedGroceryItem item;
  const _DetectedItemTile({required this.item});

  @override
  State<_DetectedItemTile> createState() => _DetectedItemTileState();
}

class _DetectedItemTileState extends State<_DetectedItemTile> {
  late TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    final q = widget.item.quantity;
    _qtyCtrl = TextEditingController(
      text: q == q.truncateToDouble() ? q.toInt().toString() : q.toString(),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CkCard(
        padding: CkCardPadding.sm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CkCheckbox(
                  value: item.selected,
                  onChanged: (v) => setState(() => item.selected = v),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: item.selected
                              ? context.appHeading
                              : context.appMuted,
                          decoration:
                              item.selected ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      if (item.category != null)
                        Text(
                          item.category!,
                          style: TextStyle(
                              fontSize: 12, color: context.appMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.selected)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 68,
                      child: CkInput(
                        controller: _qtyCtrl,
                        inputSize: CkInputSize.sm,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (v) =>
                            item.quantity = double.tryParse(v) ?? 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: CkSelect(
                        value: item.unit,
                        options: _scanUnits
                            .map((u) => CkSelectOption(value: u, label: u))
                            .toList(),
                        onChanged: (v) => setState(() => item.unit = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 96,
                      child: CkSelect(
                        value: item.storageLocation,
                        options: _scanLocations
                            .map((l) => CkSelectOption(
                                  value: l,
                                  label:
                                      '${_locationEmoji(l)} ${l[0].toUpperCase()}${l.substring(1)}',
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => item.storageLocation = v),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _locationEmoji(String loc) => switch (loc) {
      'fridge' => '❄️',
      'freezer' => '🧊',
      _ => '🥫',
    };
