import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../repositories/inventory_repository.dart';

/// Scans a product barcode and adds the resolved item to the pantry via
/// `POST /api/inventory/barcode` (FatSecret-backed).
class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  bool _handling = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final barcodes = capture.barcodes;
    final code = barcodes.isNotEmpty ? barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    setState(() => _handling = true);
    try {
      await ref.read(inventoryRepositoryProvider).addByBarcode(code, 1, 'unit');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added to pantry')));
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No product found for that barcode')));
      setState(() => _handling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_handling) const Center(child: CircularProgressIndicator()),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Point the camera at a product barcode',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
