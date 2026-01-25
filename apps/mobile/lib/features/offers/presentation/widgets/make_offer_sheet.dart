import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../application/offer_provider.dart';
import '../../domain/entities/offer.dart';

/// Shows a bottom sheet to make an offer on a listing
Future<Offer?> showMakeOfferSheet(
  BuildContext context, {
  required String listingId,
  required String listingTitle,
  required String? listingImageUrl,
  required int listingPrice,
  required String sellerId,
  required String sellerName,
  required String? sellerPhotoUrl,
  String? chatId,
}) async {
  Offer? result;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MakeOfferSheet(
      listingId: listingId,
      listingTitle: listingTitle,
      listingImageUrl: listingImageUrl,
      listingPrice: listingPrice,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhotoUrl: sellerPhotoUrl,
      chatId: chatId,
      onOfferMade: (offer) {
        result = offer;
      },
    ),
  );

  return result;
}

class _MakeOfferSheet extends ConsumerStatefulWidget {
  const _MakeOfferSheet({
    required this.listingId,
    required this.listingTitle,
    required this.listingImageUrl,
    required this.listingPrice,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhotoUrl,
    this.chatId,
    required this.onOfferMade,
  });

  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final int listingPrice;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final String? chatId;
  final void Function(Offer offer) onOfferMade;

  @override
  ConsumerState<_MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends ConsumerState<_MakeOfferSheet> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  final bool _showSuggestions = true;

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  int? get _enteredAmount {
    final text = _amountController.text.replaceAll(',', '').replaceAll(' ', '');
    return int.tryParse(text);
  }

  int get _discount {
    final amount = _enteredAmount;
    if (amount == null || amount <= 0 || widget.listingPrice <= 0) return 0;
    return (((widget.listingPrice - amount) / widget.listingPrice) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createOfferProvider);

    ref.listen<CreateOfferState>(createOfferProvider, (prev, next) {
      if (next.createdOffer != null && prev?.createdOffer != next.createdOffer) {
        widget.onOfferMade(next.createdOffer!);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  'Make an Offer',
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing info
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                          image: widget.listingImageUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(widget.listingImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.listingImageUrl == null
                            ? const Icon(Icons.image, color: AppColors.gray400)
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.listingTitle,
                              style: AppTypography.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Listed at UGX ${_formatNumber(widget.listingPrice)}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Amount input
                  Text(
                    'Your offer amount',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixText: 'UGX ',
                      hintText: 'Enter amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      suffixIcon: _enteredAmount != null && _discount > 0
                          ? Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Chip(
                                label: Text(
                                  '-$_discount%',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                                backgroundColor: AppColors.successContainer,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                          : null,
                    ),
                    onChanged: (_) {
                      setState(() {});
                      final amount = _enteredAmount;
                      if (amount != null) {
                        ref.read(createOfferProvider.notifier).setAmount(amount);
                      }
                    },
                  ),

                  // Quick suggestions
                  if (_showSuggestions) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      'Quick suggestions',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: 8,
                      children: [10, 15, 20, 25].map((percent) {
                        final suggestedAmount = (widget.listingPrice * (100 - percent) / 100).round();
                        return ActionChip(
                          label: Text('-$percent% (${_formatNumber(suggestedAmount)})'),
                          onPressed: () {
                            _amountController.text = suggestedAmount.toString();
                            ref.read(createOfferProvider.notifier).setAmount(suggestedAmount);
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.space6),

                  // Message input
                  Text(
                    'Message (optional)',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Add a message to the seller...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    onChanged: (value) {
                      ref.read(createOfferProvider.notifier).setMessage(
                        value.trim().isEmpty ? null : value.trim(),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.space4),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Text(
                            'Offers expire after 48 hours if not responded to.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error message
                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.space4),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 20,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.space3),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom action
          Container(
            padding: AppSpacing.screenPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: AppTheme.stickyShadow,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_enteredAmount != null && _enteredAmount! > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your offer:',
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            'UGX ${_formatNumber(_enteredAmount!)}',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _enteredAmount == null || _enteredAmount! <= 0 || state.isLoading
                          ? null
                          : _submitOffer,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Send Offer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOffer() async {
    final notifier = ref.read(createOfferProvider.notifier);

    await notifier.createOffer(
      CreateOfferRequest(
        listingId: widget.listingId,
        listingTitle: widget.listingTitle,
        listingImageUrl: widget.listingImageUrl,
        listingPrice: widget.listingPrice,
        sellerId: widget.sellerId,
        sellerName: widget.sellerName,
        sellerPhotoUrl: widget.sellerPhotoUrl,
        amount: _enteredAmount!,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        chatId: widget.chatId,
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }
}
