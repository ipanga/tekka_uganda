import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../application/rate_app_provider.dart';

/// Dialog prompting user to rate the app
class RateAppDialog extends ConsumerWidget {
  const RateAppDialog({super.key});

  /// Show the rate app dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RateAppDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateAppState = ref.watch(rateAppProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.space4),

          // App icon / star rating visual
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.space5),

          Text(
            'Enjoying Tekka?',
            style: AppTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space2),

          Text(
            'If you like using Tekka, please take a moment to rate us. It really helps!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Star rating display (decorative)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.star_rounded,
                  size: 32,
                  color: AppColors.warning,
                ),
              );
            }),
          ),

          const SizedBox(height: AppSpacing.space4),
        ],
      ),
      actions: [
        // Not now / Later button
        TextButton(
          onPressed: rateAppState.isLoading
              ? null
              : () {
                  ref.read(rateAppProvider.notifier).recordPrompt();
                  Navigator.of(context).pop();
                },
          child: const Text('Maybe Later'),
        ),

        // Don't ask again
        TextButton(
          onPressed: rateAppState.isLoading
              ? null
              : () {
                  ref.read(rateAppProvider.notifier).setDontAskAgain(true);
                  Navigator.of(context).pop();
                },
          child: Text(
            'Don\'t Ask Again',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),

        // Rate now button
        FilledButton(
          onPressed: rateAppState.isLoading
              ? null
              : () async {
                  final success =
                      await ref.read(rateAppProvider.notifier).requestInAppReview();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your support!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
          child: rateAppState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Text('Rate Now'),
        ),
      ],
    );
  }
}

/// A simpler bottom sheet for rate app prompts
class RateAppBottomSheet extends ConsumerWidget {
  const RateAppBottomSheet({super.key});

  /// Show the rate app bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const RateAppBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateAppState = ref.watch(rateAppProvider);
    final notifier = ref.read(rateAppProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: AppSpacing.space5),

            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate Tekka',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your feedback helps us improve',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space5),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: rateAppState.isLoading
                        ? null
                        : () {
                            notifier.recordPrompt();
                            Navigator.of(context).pop();
                          },
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: rateAppState.isLoading
                        ? null
                        : () async {
                            final success = await notifier.requestInAppReview();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thank you for rating us!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          },
                    child: rateAppState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text('Rate on ${notifier.storeName}'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space2),
          ],
        ),
      ),
    );
  }
}
