import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/meetup_provider.dart';
import '../../domain/entities/meetup_location.dart';

/// Screen showing details of a single meetup with actions
class MeetupDetailScreen extends ConsumerWidget {
  final String meetupId;

  const MeetupDetailScreen({
    super.key,
    required this.meetupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetupAsync = ref.watch(scheduledMeetupProvider(meetupId));
    final user = ref.watch(authStateProvider).valueOrNull;
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meetup Details'),
      ),
      body: meetupAsync.when(
        data: (meetup) {
          if (meetup == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'Meetup not found',
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

          final isBuyer = meetup.buyerId == userId;
          final isProposed = meetup.status == MeetupStatus.proposed;
          final isConfirmed = meetup.status == MeetupStatus.confirmed;
          final canConfirm = isProposed && !isBuyer; // Seller confirms
          final canCancel = isProposed || isConfirmed;
          final canComplete = isConfirmed && meetup.scheduledAt.isBefore(DateTime.now());
          final canMarkNoShow = isConfirmed && meetup.scheduledAt.isBefore(DateTime.now());

          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                _StatusBanner(meetup: meetup),

                const SizedBox(height: AppSpacing.space6),

                // Date & Time card
                _InfoCard(
                  icon: Icons.calendar_today,
                  title: 'Date & Time',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatFullDate(meetup.scheduledAt),
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meetup.formattedTime,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (meetup.isUpcoming) ...[
                        const SizedBox(height: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getTimeUntil(meetup.scheduledAt),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.space4),

                // Location card
                _InfoCard(
                  icon: Icons.location_on,
                  title: 'Location',
                  trailing: meetup.location.isVerified
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetup.location.name,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meetup.location.address,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (meetup.location.area.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meetup.location.area,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.space3),
                      // Location type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          meetup.location.type.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      // Amenities
                      if (meetup.location.amenities.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.space3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: meetup.location.amenities.map((amenity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gray100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getAmenityIcon(amenity),
                                    size: 14,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    amenity,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.space4),
                      // Map button
                      OutlinedButton.icon(
                        onPressed: () => _openMaps(
                          meetup.location.latitude,
                          meetup.location.longitude,
                          meetup.location.name,
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Open in Maps'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.space4),

                // Role card
                _InfoCard(
                  icon: isBuyer ? Icons.shopping_bag_outlined : Icons.sell_outlined,
                  title: 'Your Role',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isBuyer
                              ? AppColors.primaryContainer
                              : AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isBuyer ? 'Buyer' : 'Seller',
                          style: AppTypography.labelLarge.copyWith(
                            color: isBuyer ? AppColors.primary : AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Notes card
                if (meetup.notes != null && meetup.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  _InfoCard(
                    icon: Icons.note_outlined,
                    title: 'Notes',
                    child: Text(
                      meetup.notes!,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],

                // Cancel reason
                if (meetup.status == MeetupStatus.cancelled &&
                    meetup.cancelReason != null) ...[
                  const SizedBox(height: AppSpacing.space4),
                  _InfoCard(
                    icon: Icons.cancel_outlined,
                    title: 'Cancellation Reason',
                    child: Text(
                      meetup.cancelReason!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.space8),

                // Action buttons
                if (canConfirm)
                  _ActionButton(
                    label: 'Confirm Meetup',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    onPressed: () => _confirmMeetup(context, ref),
                  ),

                if (canComplete) ...[
                  _ActionButton(
                    label: 'Mark as Completed',
                    icon: Icons.task_alt,
                    color: AppColors.primary,
                    onPressed: () => _completeMeetup(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],

                if (canMarkNoShow) ...[
                  _ActionButton(
                    label: 'Report No-Show',
                    icon: Icons.person_off_outlined,
                    color: AppColors.warning,
                    isOutlined: true,
                    onPressed: () => _markNoShow(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],

                if (canCancel)
                  _ActionButton(
                    label: 'Cancel Meetup',
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    isOutlined: true,
                    onPressed: () => _showCancelDialog(context, ref),
                  ),

                const SizedBox(height: AppSpacing.space6),

                // Chat button
                if (meetup.status != MeetupStatus.cancelled &&
                    meetup.status != MeetupStatus.noShow)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/chat/${meetup.chatId}'),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Go to Chat'),
                    ),
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
                'Error loading meetup',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.refresh(scheduledMeetupProvider(meetupId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getTimeUntil(DateTime dateTime) {
    final now = DateTime.now();
    final diff = dateTime.difference(now);

    if (diff.inMinutes < 60) {
      return 'Starting in ${diff.inMinutes} minutes!';
    } else if (diff.inHours < 24) {
      return 'Coming up in ${diff.inHours} hours';
    } else {
      return 'In ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    }
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'cctv':
        return Icons.videocam;
      case 'security':
        return Icons.security;
      case 'parking':
        return Icons.local_parking;
      case 'wifi':
        return Icons.wifi;
      case 'restroom':
        return Icons.wc;
      default:
        return Icons.check_circle_outline;
    }
  }

  Future<void> _openMaps(double lat, double lng, String label) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmMeetup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Meetup'),
        content: const Text(
          'Are you sure you want to confirm this meetup? '
          'The buyer will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(meetupActionsProvider(meetupId).notifier).confirm();
      ref.invalidate(scheduledMeetupProvider(meetupId));
    }
  }

  Future<void> _completeMeetup(BuildContext context, WidgetRef ref) async {
    final completed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Meetup'),
        content: const Text(
          'Mark this meetup as completed? '
          'You\'ll be able to leave a review afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (completed == true) {
      await ref.read(meetupActionsProvider(meetupId).notifier).complete();
      ref.invalidate(scheduledMeetupProvider(meetupId));
    }
  }

  Future<void> _markNoShow(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report No-Show'),
        content: const Text(
          'Report that the other party didn\'t show up? '
          'This will be recorded on their profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(meetupActionsProvider(meetupId).notifier).markNoShow();
      ref.invalidate(scheduledMeetupProvider(meetupId));
    }
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Meetup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Cancel Meetup'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await ref.read(meetupActionsProvider(meetupId).notifier).cancel(reason);
      ref.invalidate(scheduledMeetupProvider(meetupId));
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final ScheduledMeetup meetup;

  const _StatusBanner({required this.meetup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: _getStatusColor(meetup.status).withValues(alpha: 0.1),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: _getStatusColor(meetup.status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(meetup.status),
            color: _getStatusColor(meetup.status),
            size: 32,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meetup.status.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    color: _getStatusColor(meetup.status),
                  ),
                ),
                Text(
                  _getStatusDescription(meetup.status),
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

  Color _getStatusColor(MeetupStatus status) {
    switch (status) {
      case MeetupStatus.proposed:
        return AppColors.warning;
      case MeetupStatus.confirmed:
        return AppColors.success;
      case MeetupStatus.completed:
        return AppColors.primary;
      case MeetupStatus.cancelled:
        return AppColors.error;
      case MeetupStatus.noShow:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(MeetupStatus status) {
    switch (status) {
      case MeetupStatus.proposed:
        return Icons.schedule;
      case MeetupStatus.confirmed:
        return Icons.check_circle;
      case MeetupStatus.completed:
        return Icons.task_alt;
      case MeetupStatus.cancelled:
        return Icons.cancel;
      case MeetupStatus.noShow:
        return Icons.person_off;
    }
  }

  String _getStatusDescription(MeetupStatus status) {
    switch (status) {
      case MeetupStatus.proposed:
        return 'Waiting for seller confirmation';
      case MeetupStatus.confirmed:
        return 'Both parties have agreed to meet';
      case MeetupStatus.completed:
        return 'This meetup has been completed';
      case MeetupStatus.cancelled:
        return 'This meetup was cancelled';
      case MeetupStatus.noShow:
        return 'One party did not show up';
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
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
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isOutlined;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.isOutlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
          label: Text(label, style: TextStyle(color: color)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
        ),
      ),
    );
  }
}
