import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/offer_provider.dart';
import '../../domain/entities/offer.dart';

/// Screen showing user's offers (sent and received)
class MyOffersScreen extends ConsumerStatefulWidget {
  const MyOffersScreen({super.key});

  @override
  ConsumerState<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends ConsumerState<MyOffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Offers'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sent'),
            Tab(text: 'Received'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SentOffersTab(),
          _ReceivedOffersTab(),
        ],
      ),
    );
  }
}

class _SentOffersTab extends ConsumerWidget {
  const _SentOffersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(myOffersStreamProvider);

    return offersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text('Failed to load offers: $e'),
            TextButton(
              onPressed: () => ref.invalidate(myOffersStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (offers) {
        if (offers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_offer_outlined,
            title: 'No offers sent',
            subtitle: 'Offers you make on items will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myOffersStreamProvider),
          child: ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return _OfferCard(
                offer: offers[index],
                isSentOffer: true,
              );
            },
          ),
        );
      },
    );
  }
}

class _ReceivedOffersTab extends ConsumerWidget {
  const _ReceivedOffersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(receivedOffersStreamProvider);

    return offersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text('Failed to load offers: $e'),
            TextButton(
              onPressed: () => ref.invalidate(receivedOffersStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (offers) {
        if (offers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No offers received',
            subtitle: 'Offers from buyers will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(receivedOffersStreamProvider),
          child: ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return _OfferCard(
                offer: offers[index],
                isSentOffer: false,
              );
            },
          ),
        );
      },
    );
  }
}

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.space4),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _OfferCard extends ConsumerWidget {
  final Offer offer;
  final bool isSentOffer;

  const _OfferCard({
    required this.offer,
    required this.isSentOffer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveStatus = offer.effectiveStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          // Main content - tappable to view listing
          InkWell(
            onTap: () {
              context.push(AppRoutes.listingDetail.replaceFirst(':id', offer.listingId));
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing image
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                      image: offer.listingImageUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(offer.listingImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: offer.listingImageUrl == null
                        ? const Icon(Icons.image, color: AppColors.gray400)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.space3),

                  // Offer details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.listingTitle,
                          style: AppTypography.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Your offer: ',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              offer.formattedAmount,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Listed at ${offer.formattedListingPrice}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (offer.counterAmount != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Counter: ',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                              Text(
                                offer.formattedCounterAmount!,
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status badge
                  _StatusBadge(status: effectiveStatus),
                ],
              ),
            ),
          ),

          // User info row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: (isSentOffer ? offer.sellerPhotoUrl : offer.buyerPhotoUrl) != null
                      ? CachedNetworkImageProvider(
                          isSentOffer ? offer.sellerPhotoUrl! : offer.buyerPhotoUrl!)
                      : null,
                  child: (isSentOffer ? offer.sellerPhotoUrl : offer.buyerPhotoUrl) == null
                      ? Icon(Icons.person, size: 14, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    isSentOffer ? 'To ${offer.sellerName}' : 'From ${offer.buyerName}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  offer.timeAgo,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (effectiveStatus == OfferStatus.pending) ...[
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    offer.timeRemaining,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions (if applicable)
          if (_shouldShowActions(effectiveStatus, isSentOffer))
            _buildActions(context, ref, effectiveStatus, isSentOffer),
        ],
      ),
    );
  }

  bool _shouldShowActions(OfferStatus status, bool isSentOffer) {
    if (isSentOffer) {
      // Buyer can withdraw pending offers or respond to counters
      return status == OfferStatus.pending || status == OfferStatus.countered;
    } else {
      // Seller can respond to pending offers
      return status == OfferStatus.pending;
    }
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, OfferStatus status, bool isSentOffer) {
    if (isSentOffer) {
      if (status == OfferStatus.pending) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _withdrawOffer(context, ref),
                  child: const Text('Withdraw'),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: FilledButton(
                  onPressed: () => _openChat(context),
                  child: const Text('Message'),
                ),
              ),
            ],
          ),
        );
      } else if (status == OfferStatus.countered) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineCounter(context, ref),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: FilledButton(
                  onPressed: () => _acceptCounter(context, ref),
                  child: const Text('Accept Counter'),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Seller actions for pending offers
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _declineOffer(context, ref),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showCounterDialog(context, ref),
                child: const Text('Counter'),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: FilledButton(
                onPressed: () => _acceptOffer(context, ref),
                child: const Text('Accept'),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _withdrawOffer(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Offer'),
        content: const Text('Are you sure you want to withdraw this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(offerActionsProvider(offer.id).notifier).withdraw();
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _acceptOffer(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Offer'),
        content: Text('Accept offer of ${offer.formattedAmount}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(offerActionsProvider(offer.id).notifier).accept();
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _declineOffer(BuildContext context, WidgetRef ref) {
    ref.read(offerActionsProvider(offer.id).notifier).decline();
  }

  void _declineCounter(BuildContext context, WidgetRef ref) {
    ref.read(offerActionsProvider(offer.id).notifier).withdraw();
  }

  void _acceptCounter(BuildContext context, WidgetRef ref) {
    // When buyer accepts counter, we treat it as accepting the seller's terms
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Agreed to ${offer.formattedCounterAmount}! Message the seller to finalize.')),
    );
    _openChat(context);
  }

  void _showCounterDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Counter Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original offer: ${offer.formattedAmount}'),
            const SizedBox(height: AppSpacing.space4),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Your counter amount (UGX)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                ref.read(offerActionsProvider(offer.id).notifier).counter(amount, null);
              }
            },
            child: const Text('Send Counter'),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context) {
    if (offer.chatId != null) {
      context.push(AppRoutes.chat.replaceFirst(':id', offer.chatId!));
    } else {
      // Navigate to listing to start chat
      context.push(AppRoutes.listingDetail.replaceFirst(':id', offer.listingId));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final OfferStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case OfferStatus.pending:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
      case OfferStatus.accepted:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
      case OfferStatus.declined:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
      case OfferStatus.countered:
        backgroundColor = AppColors.secondary.withValues(alpha: 0.1);
        textColor = AppColors.secondary;
      case OfferStatus.expired:
        backgroundColor = AppColors.gray200;
        textColor = AppColors.onSurfaceVariant;
      case OfferStatus.withdrawn:
        backgroundColor = AppColors.gray200;
        textColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: AppTypography.labelSmall.copyWith(color: textColor),
      ),
    );
  }
}
