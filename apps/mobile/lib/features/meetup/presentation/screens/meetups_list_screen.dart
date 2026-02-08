import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/meetup_provider.dart';
import '../../domain/entities/meetup_location.dart';

/// Screen displaying user's scheduled meetups
class MeetupsListScreen extends ConsumerWidget {
  const MeetupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final userId = user?.uid ?? '';
    final upcomingMeetupsAsync = ref.watch(upcomingMeetupsProvider(userId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Meetups'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              tooltip: 'Safe Locations',
              onPressed: () => context.push('/meetups/locations'),
            ),
          ],
        ),
        body: upcomingMeetupsAsync.when(
          data: (meetups) {
            final now = DateTime.now();
            final upcoming = meetups
                .where(
                  (m) =>
                      m.scheduledAt.isAfter(now) &&
                      m.status != MeetupStatus.completed &&
                      m.status != MeetupStatus.cancelled,
                )
                .toList();
            final past = meetups
                .where(
                  (m) =>
                      m.scheduledAt.isBefore(now) ||
                      m.status == MeetupStatus.completed ||
                      m.status == MeetupStatus.cancelled,
                )
                .toList();

            return TabBarView(
              children: [
                _MeetupsList(
                  meetups: upcoming,
                  emptyMessage: 'No upcoming meetups',
                  emptySubtitle: 'Schedule meetups from your chats',
                  userId: userId,
                ),
                _MeetupsList(
                  meetups: past,
                  emptyMessage: 'No past meetups',
                  emptySubtitle: 'Your completed meetups will appear here',
                  userId: userId,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Failed to load meetups',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.space2),
                TextButton(
                  onPressed: () => ref.refresh(upcomingMeetupsProvider(userId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetupsList extends StatelessWidget {
  final List<ScheduledMeetup> meetups;
  final String emptyMessage;
  final String emptySubtitle;
  final String userId;

  const _MeetupsList({
    required this.meetups,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    if (meetups.isEmpty) {
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
              emptyMessage,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              emptySubtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: meetups.length,
      itemBuilder: (context, index) {
        final meetup = meetups[index];
        return _MeetupCard(
          meetup: meetup,
          userId: userId,
          onTap: () => context.push('/meetups/${meetup.id}'),
        );
      },
    );
  }
}

class _MeetupCard extends StatelessWidget {
  final ScheduledMeetup meetup;
  final String userId;
  final VoidCallback onTap;

  const _MeetupCard({
    required this.meetup,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBuyer = meetup.buyerId == userId;
    final isUpcoming = meetup.isUpcoming;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: isUpcoming ? AppColors.primary : AppColors.outline,
            width: isUpcoming ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(meetup.status).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusMd - 1),
                  topRight: Radius.circular(AppSpacing.radiusMd - 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(meetup.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      meetup.status.displayName,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isBuyer
                          ? AppColors.primaryContainer
                          : AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isBuyer ? 'Buying' : 'Selling',
                      style: AppTypography.labelSmall.copyWith(
                        color: isBuyer
                            ? AppColors.primary
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        meetup.formattedDate,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(width: AppSpacing.space4),
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        meetup.formattedTime,
                        style: AppTypography.titleMedium,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.space3),

                  // Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meetup.location.name,
                              style: AppTypography.bodyLarge,
                            ),
                            Text(
                              meetup.location.address,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (meetup.location.isVerified)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified_user,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),

                  // Notes
                  if (meetup.notes != null && meetup.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space2),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: Text(
                              meetup.notes!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Upcoming indicator
                  if (isUpcoming) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: Text(
                              _getTimeUntil(meetup.scheduledAt),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
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
          ],
        ),
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
}
