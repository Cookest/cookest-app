import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../repositories/stores_repository.dart';
import '../widgets/price_chip.dart';

class StoreDetailScreen extends ConsumerWidget {
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(storePromotionsProvider(storeId));
    return Scaffold(
      appBar: AppBar(title: const Text('Promotions')),
      body: promosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text('Could not load promotions',
              style: TextStyle(color: context.appMuted)),
        ),
        data: (promos) {
          if (promos.isEmpty) {
            return Center(
              child: Text('No active promotions',
                  style: TextStyle(color: context.appMuted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: promos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = promos[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.productName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: context.appHeading)),
                          if (p.brand != null)
                            Text(p.brand!,
                                style: TextStyle(
                                    fontSize: 12, color: context.appMuted)),
                          if (p.validUntil != null)
                            Text('Until ${DateFormat.yMMMd().format(p.validUntil!)}',
                                style: TextStyle(
                                    fontSize: 11, color: context.appMuted)),
                        ],
                      ),
                    ),
                    PriceChip(promotion: p),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
