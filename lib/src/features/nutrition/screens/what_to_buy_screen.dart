import 'package:cookest_ui/cookest_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../repositories/nutrition_repository.dart';

/// AI-suggested groceries that fill nutritional gaps, grounded in the
/// nutrition knowledge base (RAG).
class WhatToBuyScreen extends ConsumerWidget {
  const WhatToBuyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(whatToBuyProvider(''));
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: const Text('What to buy')),
      body: async.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Asking the AI…'),
            ],
          ),
        ),
        error: (_, _) => Center(
          child: Text('Could not get suggestions',
              style: TextStyle(color: context.appMuted)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text('No suggestions right now',
                  style: TextStyle(color: context.appMuted)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(whatToBuyProvider('')),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = items[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.sparkles,
                          color: CookestTokens.colorPrimaryDEFAULT),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(s.item,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: context.appHeading)),
                                ),
                                if (s.nutrient != null && s.nutrient!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CookestTokens.colorPrimaryDEFAULT
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(s.nutrient!,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: CookestTokens
                                                .colorPrimaryDEFAULT)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(s.reason,
                                style: TextStyle(
                                    fontSize: 13, color: context.appMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
