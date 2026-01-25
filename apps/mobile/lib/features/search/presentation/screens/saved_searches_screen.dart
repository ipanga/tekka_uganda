import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/saved_search_provider.dart';
import '../../domain/entities/saved_search.dart';

/// Screen showing user's saved searches
class SavedSearchesScreen extends ConsumerWidget {
  const SavedSearchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchesAsync = ref.watch(savedSearchesStreamProvider);
    final state = ref.watch(savedSearchProvider);

    // Listen for errors
    ref.listen<SavedSearchState>(savedSearchProvider, (prev, next) {
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(savedSearchProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Searches'),
        actions: [
          searchesAsync.maybeWhen(
            data: (searches) => searches.isNotEmpty
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'clear_all') {
                        _showClearAllDialog(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'clear_all',
                        child: Text('Clear all'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: searchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load saved searches', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(savedSearchesStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (searches) {
          if (searches.isEmpty) {
            return _buildEmptyState(context);
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: searches.length,
                itemBuilder: (context, index) {
                  final search = searches[index];
                  return _SavedSearchTile(
                    search: search,
                    onTap: () => _executeSearch(context, ref, search),
                    onToggleNotifications: (enabled) {
                      ref
                          .read(savedSearchProvider.notifier)
                          .toggleNotifications(search.id, enabled);
                    },
                    onDelete: () => _deleteSearch(context, ref, search.id),
                  );
                },
              ),
              if (state.isLoading)
                Container(
                  color: AppColors.gray900.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.saved_search,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              'No Saved Searches',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Save your searches to get notified when new items match your criteria.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.browse),
              icon: const Icon(Icons.search),
              label: const Text('Start Searching'),
            ),
          ],
        ),
      ),
    );
  }

  void _executeSearch(BuildContext context, WidgetRef ref, SavedSearch search) {
    // Clear new match count
    ref.read(savedSearchProvider.notifier).clearNewMatches(search.id);

    // Navigate to browse with search params
    // Using query parameters to pass search filters
    final queryParams = <String, String>{
      'q': search.query,
    };

    if (search.categoryId != null) {
      queryParams['category'] = search.categoryId!;
    }
    if (search.minPrice != null) {
      queryParams['minPrice'] = search.minPrice.toString();
    }
    if (search.maxPrice != null) {
      queryParams['maxPrice'] = search.maxPrice.toString();
    }
    if (search.location != null) {
      queryParams['location'] = search.location!;
    }
    if (search.condition != null) {
      queryParams['condition'] = search.condition!;
    }

    final uri = Uri(
      path: AppRoutes.browse,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    context.go(uri.toString());
  }

  void _deleteSearch(BuildContext context, WidgetRef ref, String searchId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Saved Search'),
        content: const Text('Are you sure you want to delete this saved search?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(savedSearchProvider.notifier).deleteSearch(searchId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Searches'),
        content: const Text(
          'Are you sure you want to delete all saved searches? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(savedSearchProvider.notifier).clearAll();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _SavedSearchTile extends StatelessWidget {
  const _SavedSearchTile({
    required this.search,
    required this.onTap,
    required this.onToggleNotifications,
    required this.onDelete,
  });

  final SavedSearch search;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleNotifications;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(search.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: AppColors.white,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                  ),
                  if (search.newMatchCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          search.newMatchCount > 99
                              ? '99+'
                              : search.newMatchCount.toString(),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.space3),

              // Search details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            search.query.isEmpty ? 'All items' : '"${search.query}"',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (search.newMatchCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${search.newMatchCount} new',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      search.filterSummary,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Saved ${search.timeAgo}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.gray400,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        // Notification toggle
                        GestureDetector(
                          onTap: () =>
                              onToggleNotifications(!search.notificationsEnabled),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                search.notificationsEnabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_off_outlined,
                                size: 16,
                                color: search.notificationsEnabled
                                    ? AppColors.primary
                                    : AppColors.gray400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                search.notificationsEnabled ? 'On' : 'Off',
                                style: AppTypography.labelSmall.copyWith(
                                  color: search.notificationsEnabled
                                      ? AppColors.primary
                                      : AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              const SizedBox(width: AppSpacing.space2),
              Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
