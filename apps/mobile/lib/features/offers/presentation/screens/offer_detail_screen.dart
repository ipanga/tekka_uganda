import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/offer_provider.dart';
import '../../domain/entities/offer.dart';

/// Screen showing details of a single offer
class OfferDetailScreen extends ConsumerWidget {
  final String offerId;

  const OfferDetailScreen({
    super.key,
    required this.offerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerAsync = ref.watch(offerProvider(offerId));
    final user = ref.watch(authStateProvider).valueOrNull;
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offer Details'),
      ),
      body: offerAsync.when(
        data: (offer) {
          if (offer == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'Offer not found',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final isBuyer = offer.buyerId == userId;
          final effectiveStatus = offer.effectiveStatus;

          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                _StatusBanner(status: effectiveStatus),

                const SizedBox(height: AppSpacing.space6),

                // Listing card
                _ListingCard(offer: offer),

                const SizedBox(height: AppSpacing.space6),

                // Offer details card
                _OfferDetailsCard(offer: offer, isBuyer: isBuyer),

                const SizedBox(height: AppSpacing.space6),

                // Counter offer card (if countered)
                if (offer.counterAmount != null)
                  _CounterOfferCard(offer: offer),

                if (offer.counterAmount != null)
                  const SizedBox(height: AppSpacing.space6),

                // Timeline card
                _TimelineCard(offer: offer),

                const SizedBox(height: AppSpacing.space6),

                // Actions
                _ActionsSection(
                  offer: offer,
                  isBuyer: isBuyer,
                  effectiveStatus: effectiveStatus,
                ),

                const SizedBox(height: AppSpacing.space8),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Error loading offer',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.refresh(offerProvider(offerId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final OfferStatus status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 32,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    color: _getStatusColor(status),
                  ),
                ),
                Text(
                  _getStatusDescription(status),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return AppColors.warning;
      case OfferStatus.accepted:
        return AppColors.success;
      case OfferStatus.declined:
        return AppColors.error;
      case OfferStatus.countered:
        return AppColors.secondary;
      case OfferStatus.expired:
        return AppColors.onSurfaceVariant;
      case OfferStatus.withdrawn:
        return AppColors.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return Icons.schedule;
      case OfferStatus.accepted:
        return Icons.check_circle;
      case OfferStatus.declined:
        return Icons.cancel;
      case OfferStatus.countered:
        return Icons.swap_horiz;
      case OfferStatus.expired:
        return Icons.timer_off;
      case OfferStatus.withdrawn:
        return Icons.undo;
    }
  }

  String _getStatusDescription(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return 'Waiting for seller response';
      case OfferStatus.accepted:
        return 'Offer accepted! Message the seller to arrange meetup';
      case OfferStatus.declined:
        return 'The seller declined this offer';
      case OfferStatus.countered:
        return 'Seller has proposed a counter offer';
      case OfferStatus.expired:
        return 'This offer has expired';
      case OfferStatus.withdrawn:
        return 'This offer was withdrawn';
    }
  }
}

class _ListingCard extends StatelessWidget {
  final Offer offer;

  const _ListingCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.listingDetail.replaceFirst(':id', offer.listingId),
      ),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
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
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.listingTitle,
                    style: AppTypography.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.formattedListingPrice,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferDetailsCard extends StatelessWidget {
  final Offer offer;
  final bool isBuyer;

  const _OfferDetailsCard({
    required this.offer,
    required this.isBuyer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'Offer Amount',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Amount display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                offer.formattedAmount,
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              if (offer.discountPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '-${offer.discountPercent}% off',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Message
          if (offer.message != null && offer.message!.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.space3),
            Text(
              'Message:',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              offer.message!,
              style: AppTypography.bodyMedium,
            ),
          ],

          const Divider(),
          const SizedBox(height: AppSpacing.space3),

          // Party info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: (isBuyer ? offer.sellerPhotoUrl : offer.buyerPhotoUrl) != null
                    ? CachedNetworkImageProvider(
                        isBuyer ? offer.sellerPhotoUrl! : offer.buyerPhotoUrl!)
                    : null,
                child: (isBuyer ? offer.sellerPhotoUrl : offer.buyerPhotoUrl) == null
                    ? Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBuyer ? offer.sellerName : offer.buyerName,
                      style: AppTypography.titleSmall,
                    ),
                    Text(
                      isBuyer ? 'Seller' : 'Buyer',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final otherUserId = isBuyer ? offer.sellerId : offer.buyerId;
                  context.push(AppRoutes.userProfile.replaceFirst(':userId', otherUserId));
                },
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('View Profile'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterOfferCard extends StatelessWidget {
  final Offer offer;

  const _CounterOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 20, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'Counter Offer',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            offer.formattedCounterAmount!,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          if (offer.counterMessage != null && offer.counterMessage!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              offer.counterMessage!,
              style: AppTypography.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final Offer offer;

  const _TimelineCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'Timeline',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Created
          _TimelineItem(
            icon: Icons.add_circle_outline,
            title: 'Offer created',
            subtitle: _formatDateTime(offer.createdAt),
            isFirst: true,
          ),

          // Responded (if applicable)
          if (offer.respondedAt != null)
            _TimelineItem(
              icon: _getResponseIcon(offer.status),
              title: _getResponseTitle(offer.status),
              subtitle: _formatDateTime(offer.respondedAt!),
              color: _getResponseColor(offer.status),
            ),

          // Expiry
          _TimelineItem(
            icon: Icons.timer_outlined,
            title: offer.effectiveStatus == OfferStatus.expired
                ? 'Expired'
                : 'Expires',
            subtitle: _formatDateTime(offer.expiresAt),
            isLast: true,
            color: offer.effectiveStatus == OfferStatus.expired
                ? AppColors.error
                : null,
          ),
        ],
      ),
    );
  }

  IconData _getResponseIcon(OfferStatus status) {
    switch (status) {
      case OfferStatus.accepted:
        return Icons.check_circle_outline;
      case OfferStatus.declined:
        return Icons.cancel_outlined;
      case OfferStatus.countered:
        return Icons.swap_horiz;
      case OfferStatus.withdrawn:
        return Icons.undo;
      default:
        return Icons.circle_outlined;
    }
  }

  String _getResponseTitle(OfferStatus status) {
    switch (status) {
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.declined:
        return 'Declined';
      case OfferStatus.countered:
        return 'Counter offered';
      case OfferStatus.withdrawn:
        return 'Withdrawn';
      default:
        return 'Updated';
    }
  }

  Color _getResponseColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.accepted:
        return AppColors.success;
      case OfferStatus.declined:
        return AppColors.error;
      case OfferStatus.countered:
        return AppColors.secondary;
      case OfferStatus.withdrawn:
        return AppColors.onSurfaceVariant;
      default:
        return AppColors.primary;
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');

    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute $period';
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final Color? color;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 12,
                color: AppColors.outline,
              ),
            Icon(icon, size: 20, color: effectiveColor),
            if (!isLast)
              Container(
                width: 2,
                height: 12,
                color: AppColors.outline,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: isFirst ? 0 : 8,
              bottom: isLast ? 0 : 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: effectiveColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionsSection extends ConsumerWidget {
  final Offer offer;
  final bool isBuyer;
  final OfferStatus effectiveStatus;

  const _ActionsSection({
    required this.offer,
    required this.isBuyer,
    required this.effectiveStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(offerActionsProvider(offer.id));

    // Show loading state
    if (actionsState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space4),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Chat button is always available (if not expired/withdrawn)
    final showChatButton = effectiveStatus != OfferStatus.expired &&
        effectiveStatus != OfferStatus.withdrawn;

    // Determine which action buttons to show
    final bool canWithdraw = isBuyer && effectiveStatus == OfferStatus.pending;
    final bool canAcceptCounter = isBuyer && effectiveStatus == OfferStatus.countered;
    final bool canDeclineCounter = isBuyer && effectiveStatus == OfferStatus.countered;
    final bool canAccept = !isBuyer && effectiveStatus == OfferStatus.pending;
    final bool canDecline = !isBuyer && effectiveStatus == OfferStatus.pending;
    final bool canCounter = !isBuyer && effectiveStatus == OfferStatus.pending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Buyer actions
        if (canWithdraw)
          OutlinedButton.icon(
            onPressed: () => _withdrawOffer(context, ref),
            icon: const Icon(Icons.undo),
            label: const Text('Withdraw Offer'),
          ),

        if (canAcceptCounter || canDeclineCounter) ...[
          Row(
            children: [
              if (canDeclineCounter)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineCounter(context, ref),
                    child: const Text('Decline Counter'),
                  ),
                ),
              if (canAcceptCounter && canDeclineCounter)
                const SizedBox(width: AppSpacing.space3),
              if (canAcceptCounter)
                Expanded(
                  child: FilledButton(
                    onPressed: () => _acceptCounter(context, ref),
                    child: const Text('Accept Counter'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Seller actions
        if (canAccept || canDecline || canCounter) ...[
          Row(
            children: [
              if (canDecline)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineOffer(context, ref),
                    child: const Text('Decline'),
                  ),
                ),
              if (canCounter) ...[
                if (canDecline) const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCounterDialog(context, ref),
                    child: const Text('Counter'),
                  ),
                ),
              ],
              if (canAccept) ...[
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _acceptOffer(context, ref),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Chat button
        if (showChatButton)
          OutlinedButton.icon(
            onPressed: () => _openChat(context),
            icon: const Icon(Icons.chat_outlined),
            label: Text(effectiveStatus == OfferStatus.accepted
                ? 'Message to Arrange Meetup'
                : 'Message'),
          ),
      ],
    );
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
              ref.invalidate(offerProvider(offer.id));
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
              ref.invalidate(offerProvider(offer.id));
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _declineOffer(BuildContext context, WidgetRef ref) {
    ref.read(offerActionsProvider(offer.id).notifier).decline();
    ref.invalidate(offerProvider(offer.id));
  }

  void _declineCounter(BuildContext context, WidgetRef ref) {
    ref.read(offerActionsProvider(offer.id).notifier).withdraw();
    ref.invalidate(offerProvider(offer.id));
  }

  void _acceptCounter(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agreed to ${offer.formattedCounterAmount}! Message the seller to finalize.'),
        backgroundColor: AppColors.success,
      ),
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
                ref.invalidate(offerProvider(offer.id));
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
      context.push(AppRoutes.listingDetail.replaceFirst(':id', offer.listingId));
    }
  }
}
