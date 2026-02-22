import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../application/review_provider.dart';
import '../../domain/entities/review.dart';

/// Screen to create or edit a review
class CreateReviewScreen extends ConsumerStatefulWidget {
  final String revieweeId;
  final String revieweeName;
  final String? listingId;
  final String? listingTitle;
  final ReviewType reviewType;
  final Review? existingReview;

  const CreateReviewScreen({
    super.key,
    required this.revieweeId,
    required this.revieweeName,
    this.listingId,
    this.listingTitle,
    this.reviewType = ReviewType.seller,
    this.existingReview,
  });

  @override
  ConsumerState<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  final _commentController = TextEditingController();
  int _selectedRating = 0;

  bool get _isEditMode => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _selectedRating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final notifier = ref.read(createReviewProvider.notifier);
    notifier.setRating(_selectedRating);
    notifier.setComment(_commentController.text.trim());

    final bool success;
    if (_isEditMode) {
      success = await notifier.update(reviewId: widget.existingReview!.id);
    } else {
      success = await notifier.submit(
        revieweeId: widget.revieweeId,
        listingId: widget.listingId,
        listingTitle: widget.listingTitle,
        type: widget.reviewType,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Review updated successfully'
                : 'Review submitted successfully',
          ),
        ),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReviewProvider);

    ref.listen<CreateReviewState>(createReviewProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Review' : 'Write Review'),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Review target info
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.cardRadius,
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  children: [
                    Text(
                      'Review for',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.revieweeName, style: AppTypography.titleLarge),
                    if (widget.listingTitle != null) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.listingTitle!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.reviewType == ReviewType.buyer
                            ? AppColors.primaryContainer
                            : AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.reviewType == ReviewType.buyer
                            ? 'Reviewing as Seller'
                            : 'Reviewing as Buyer',
                        style: AppTypography.labelSmall.copyWith(
                          color: widget.reviewType == ReviewType.buyer
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Rating selection
              Text(
                'How was your experience?',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space4),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = starIndex;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starIndex <= _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.warning,
                        size: 48,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.space2),

              Text(
                _getRatingLabel(_selectedRating),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Comment input
              Text(
                'Share your experience (optional)',
                style: AppTypography.titleSmall,
              ),

              const SizedBox(height: AppSpacing.space2),

              TextFormField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.done,
                onEditingComplete: () => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  hintText: widget.reviewType == ReviewType.buyer
                      ? 'How was the buyer? Were they punctual, easy to communicate with?'
                      : 'How was the item? Was the seller honest about the condition?',
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.cardRadius,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Submit button
              FilledButton(
                onPressed: state.isLoading || _selectedRating == 0
                    ? null
                    : _submitReview,
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditMode ? 'Update Review' : 'Submit Review'),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Guidelines
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: AppSpacing.cardRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Review Guidelines',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '• Be honest and fair in your assessment\n'
                      '• Focus on the transaction experience\n'
                      '• Avoid personal attacks or offensive language\n'
                      '• Your review helps build trust in our community',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }
}
