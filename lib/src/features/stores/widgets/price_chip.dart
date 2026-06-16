import 'package:cookest_ui/cookest_ui.dart';
import 'package:flutter/material.dart';
import '../models/store.dart';

/// Compact promotional-price chip: discounted price with the original struck
/// through. Reused on the stores screen and the shopping list.
class PriceChip extends StatelessWidget {
  final Promotion promotion;
  const PriceChip({super.key, required this.promotion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '€${promotion.discountedPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: CookestTokens.colorPrimaryDEFAULT,
              fontSize: 13,
            ),
          ),
          if (promotion.originalPrice != null) ...[
            const SizedBox(width: 6),
            Text(
              '€${promotion.originalPrice!.toStringAsFixed(2)}',
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
          if (promotion.unit != null) ...[
            const SizedBox(width: 4),
            Text('/${promotion.unit}',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
