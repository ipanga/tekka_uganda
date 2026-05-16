import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/domain/entities/listing.dart';

/// One tab on the My Listings screen — server-side status filter, a
/// dedicated paginated notifier, and (via _ListingsTab) its own scroll
/// controller so the position is preserved across tab switches.
class _TabSpec {
  final String label;
  final ListingStatus? status; // null == "All"
  final String emptyMessage;
  final String? emptyAction;
  final bool showDraftActions;

  const _TabSpec({
    required this.label,
    required this.status,
    required this.emptyMessage,
    this.emptyAction,
    this.showDraftActions = false,
  });
}

const _tabs = <_TabSpec>[
  _TabSpec(
    label: 'All',
    status: null,
    emptyMessage: 'No listings yet',
    emptyAction: 'Create your first listing',
  ),
  _TabSpec(
    label: 'Active',
    status: ListingStatus.active,
    emptyMessage: 'No active listings',
    emptyAction: 'Create a new listing',
  ),
  _TabSpec(
    label: 'Drafts',
    status: ListingStatus.draft,
    emptyMessage: 'No drafts',
    emptyAction: 'Create a listing',
    showDraftActions: true,
  ),
  _TabSpec(
    label: 'Under Review',
    status: ListingStatus.pending,
    emptyMessage: 'No listings under review',
  ),
  _TabSpec(
    label: 'Rejected',
    status: ListingStatus.rejected,
    emptyMessage: 'No rejected listings',
  ),
  _TabSpec(
    label: 'Sold',
    status: ListingStatus.sold,
    emptyMessage: 'No sold listings yet',
  ),
];

/// My listings screen — one paginated tab per status filter. Each tab
/// owns its scroll position and pagination state via
/// [myListingsListProvider].
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        title: const Text('My Listings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => _CountedTab(spec: t)).toList(growable: false),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((t) => _ListingsTab(key: ValueKey(t.label), spec: t))
            .toList(growable: false),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createListing),
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
      ),
    );
  }
}

/// Tab title that subscribes to the server-reported total via .select so the
/// label only rebuilds when the count actually changes.
class _CountedTab extends ConsumerWidget {
  const _CountedTab({required this.spec});

  final _TabSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      myListingsListProvider(spec.status).select((s) => s.total),
    );
    final isInitial = ref.watch(
      myListingsListProvider(spec.status).select((s) => s.isInitialLoading),
    );
    final suffix = (!isInitial && total > 0) ? ' ($total)' : '';
    return Tab(text: '${spec.label}$suffix');
  }
}

class _ListingsTab extends ConsumerStatefulWidget {
  const _ListingsTab({super.key, required this.spec});

  final _TabSpec spec;

  @override
  ConsumerState<_ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends ConsumerState<_ListingsTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  /// Fire loadMore when the user is within this many pixels of the end of
  /// the list. Larger threshold = earlier prefetch = smoother feel.
  static const double _loadMoreThresholdPx = 600;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= _loadMoreThresholdPx) {
      ref
          .read(myListingsListProvider(widget.spec.status).notifier)
          .loadMore();
    }
  }

  Future<void> _refresh() {
    return ref
        .read(myListingsListProvider(widget.spec.status).notifier)
        .refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin.
    final state = ref.watch(myListingsListProvider(widget.spec.status));

    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return _ErrorView(error: state.error!, onRetry: _refresh);
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 64),
            _EmptyView(spec: widget.spec),
          ],
        ),
      );
    }

    // hasMore drives a trailing "loading more" cell. Showing it as a
    // grid-spanning row would require SliverGrid + SliverList; we use the
    // simpler pattern of an extra item at the end of the grid and let it
    // render as a centered tile.
    final showTrailingLoader = state.hasMore || state.isLoadingMore;
    final itemCount = state.items.length + (showTrailingLoader ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: AppSpacing.screenPadding,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: AppSpacing.space3,
          mainAxisSpacing: AppSpacing.space3,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const _GridLoadingTile();
          }
          return _ListingCard(
            listing: state.items[index],
            status: widget.spec.status,
            showDraftActions: widget.spec.showDraftActions,
          );
        },
      ),
    );
  }
}

class _GridLoadingTile extends StatelessWidget {
  const _GridLoadingTile();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.spec});

  final _TabSpec spec;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              spec.showDraftActions
                  ? Icons.edit_note_outlined
                  : Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(spec.emptyMessage, style: AppTypography.titleMedium),
            if (spec.emptyAction != null) ...[
              const SizedBox(height: AppSpacing.space4),
              ElevatedButton(
                onPressed: () =>
                    GoRouter.of(context).push(AppRoutes.createListing),
                child: Text(spec.emptyAction!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text('Failed to load listings', style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.space2),
            Text(
              error,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.space4),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  const _ListingCard({
    required this.listing,
    required this.status,
    this.showDraftActions = false,
  });

  final Listing listing;
  // The status filter of the tab this card lives in. Used to invalidate the
  // *right* tab when a draft is published and disappears from this tab.
  final ListingStatus? status;
  final bool showDraftActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.listingDetail.replaceFirst(':id', listing.id));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: listing.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.gray100,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              // ignore: avoid_print
                              print('[tekka.image] $url -> $error');
                              developer.log(
                                'image fetch failed: $url -> $error',
                                name: 'tekka.image',
                                error: error,
                                level: 1000,
                              );
                              return Container(
                                color: AppColors.gray100,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: AppColors.gray400,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.gray100,
                            child: const Icon(
                              Icons.image,
                              color: AppColors.gray400,
                              size: 40,
                            ),
                          ),
                  ),
                  // Status badge
                  Positioned(
                    top: AppSpacing.space2,
                    left: AppSpacing.space2,
                    child: _StatusBadge(status: listing.status),
                  ),
                  // View count
                  Positioned(
                    bottom: AppSpacing.space2,
                    right: AppSpacing.space2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            listing.viewCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title.isNotEmpty ? listing.title : 'Untitled Draft',
                    style: AppTypography.labelMedium.copyWith(
                      fontStyle: listing.title.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.formattedPrice,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.timeAgo,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  // Draft inline actions
                  if (showDraftActions &&
                      listing.status == ListingStatus.draft) ...[
                    const SizedBox(height: AppSpacing.space2),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () => context.push(
                                AppRoutes.editListing.replaceFirst(
                                  ':id',
                                  listing.id,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                textStyle: AppTypography.labelSmall,
                              ),
                              child: const Text('Edit'),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: FilledButton(
                              onPressed: () => _publishDraft(context, ref),
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                textStyle: AppTypography.labelSmall,
                              ),
                              child: const Text('Publish'),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _publishDraft(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Listing'),
        content: const Text(
          'Publish this listing? It will be submitted for review before going live.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final repository = ref.read(listingApiRepositoryProvider);
      await repository.publishDraft(listing.id);

      // Refresh the detail-screen cache so the next nav reflects the new
      // status.
      ref.invalidate(listingProvider(listing.id));

      // Drop the now-pending listing from the Drafts tab instantly. The
      // Under Review + All tabs refetch in the background so they pick up
      // the new pending row in correct order. The other tabs (Active /
      // Rejected / Sold) are unaffected.
      ref
          .read(myListingsListProvider(ListingStatus.draft).notifier)
          .removeLocally(listing.id);
      ref
          .read(myListingsListProvider(ListingStatus.pending).notifier)
          .refresh();
      ref.read(myListingsListProvider(null).notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing submitted for review!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final errorStr = e is AppException ? e.message : e.toString();
        final errorMsg = errorStr.contains('must have')
            ? 'Please complete all required fields before publishing.'
            : errorStr;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String text;

    switch (status) {
      case ListingStatus.active:
        backgroundColor = AppColors.success;
        text = 'Active';
      case ListingStatus.pending:
        backgroundColor = AppColors.gold;
        text = 'Pending';
      case ListingStatus.sold:
        backgroundColor = AppColors.primary;
        text = 'Sold';
      case ListingStatus.rejected:
        backgroundColor = AppColors.error;
        text = 'Rejected';
      case ListingStatus.archived:
        backgroundColor = AppColors.gray400;
        text = 'Archived';
      case ListingStatus.draft:
        backgroundColor = AppColors.gray400;
        text = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
