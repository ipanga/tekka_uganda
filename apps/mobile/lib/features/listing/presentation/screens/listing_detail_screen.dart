import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../chat/application/chat_provider.dart';
import '../../../chat/domain/entities/chat.dart';
import '../../application/listing_provider.dart';
import '../../domain/entities/listing.dart';

/// Listing detail screen - displays full item information
class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Increment view count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(listingActionsProvider(widget.listingId).notifier)
          .incrementView();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingProvider(widget.listingId));
    final currentUser = ref.watch(currentUserProvider);

    return listingAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load listing', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () =>
                    ref.invalidate(listingProvider(widget.listingId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (listing) {
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Listing not found')),
          );
        }

        final isOwner = currentUser?.uid == listing.sellerId;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Image gallery with back button
              SliverAppBar(
                expandedHeight: AppSpacing.galleryHeight,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _ImageGallery(
                    imageUrls: listing.imageUrls,
                    currentIndex: _currentImageIndex,
                    pageController: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareListing(listing),
                  ),
                  if (!isOwner)
                    _FavoriteButton(
                      listingId: listing.id,
                      userId: currentUser?.uid,
                    ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => _handleOwnerAction(value, listing),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Listing'),
                        ),
                        const PopupMenuItem(
                          value: 'sold',
                          child: Text('Mark as Sold'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Listing'),
                        ),
                      ],
                    ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.detailOverlayRadius,
                  ),
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.space4),

                        // Status badge if not active
                        if (listing.status != ListingStatus.active) ...[
                          _StatusBadge(status: listing.status),
                          const SizedBox(height: AppSpacing.space3),
                        ],

                        // Price
                        Text(
                          listing.formattedPrice,
                          style: AppTypography.price,
                        ),
                        const SizedBox(height: AppSpacing.space2),

                        // Title
                        Text(listing.title, style: AppTypography.titleLarge),
                        const SizedBox(height: AppSpacing.space2),

                        // Location & Time
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: AppSpacing.iconSmall,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              listing.location ?? 'Unknown',
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(width: AppSpacing.space4),
                            const Icon(
                              Icons.access_time,
                              size: AppSpacing.iconSmall,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              listing.timeAgo,
                              style: AppTypography.bodySmall,
                            ),
                            const Spacer(),
                            Icon(
                              Icons.visibility_outlined,
                              size: AppSpacing.iconSmall,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              '${listing.viewCount}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.space6),
                        const Divider(),
                        const SizedBox(height: AppSpacing.space6),

                        // Details section
                        Text('Details', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.space4),

                        _DetailRow(
                          label: 'Category',
                          // Use categoryName from new system, fallback to legacy
                          value: (listing.categoryName?.isNotEmpty == true)
                              ? listing.categoryName!
                              : listing.category.displayName,
                        ),
                        _DetailRow(
                          label: 'Condition',
                          value: listing.condition.displayName,
                        ),
                        // Display all attributes from JSON or legacy fields
                        ..._buildAdditionalAttributes(listing),

                        // Occasion
                        if (listing.occasion != null) ...[
                          const SizedBox(height: AppSpacing.space4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Best For',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.space2,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  listing.occasion!.displayName,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: AppSpacing.space6),
                        const Divider(),
                        const SizedBox(height: AppSpacing.space6),

                        // Description
                        Text('Description', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.space3),
                        Text(
                          listing.description.isNotEmpty
                              ? listing.description
                              : 'No description provided.',
                          style: AppTypography.bodyMedium,
                        ),

                        const SizedBox(height: AppSpacing.space6),
                        const Divider(),
                        const SizedBox(height: AppSpacing.space6),

                        // Seller info
                        Text('Seller', style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.space4),

                        Row(
                          children: [
                            CircleAvatar(
                              radius: AppSpacing.avatarSmall / 2,
                              backgroundColor: AppColors.primaryContainer,
                              backgroundImage: listing.sellerPhotoUrl != null
                                  ? CachedNetworkImageProvider(
                                      listing.sellerPhotoUrl!,
                                    )
                                  : null,
                              child: listing.sellerPhotoUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                      size: AppSpacing.iconMedium,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listing.sellerName,
                                    style: AppTypography.labelLarge,
                                  ),
                                  Text(
                                    'Member since ${listing.createdAt.year}',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (!isOwner)
                              TextButton(
                                onPressed: () {
                                  context.push(
                                    AppRoutes.userProfile.replaceFirst(
                                      ':userId',
                                      listing.sellerId,
                                    ),
                                  );
                                },
                                child: const Text('View Profile'),
                              ),
                          ],
                        ),

                        // Space for bottom bar
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom action bar (only show for non-owners and active listings)
          bottomNavigationBar:
              !isOwner && listing.status == ListingStatus.active
              ? Container(
                  padding: AppSpacing.screenPadding,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: AppTheme.stickyShadow,
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startChat(listing),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message Seller'),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _shareListing(Listing listing) async {
    final shareText =
        '''
Check out "${listing.title}" on Tekka!

${listing.formattedPrice}
${listing.condition.displayName} condition
Location: ${listing.location}

${listing.description.isNotEmpty ? listing.description : 'No description provided.'}

Download Tekka to browse more fashion items!
''';

    await Share.share(
      shareText,
      subject: 'Check out this item on Tekka: ${listing.title}',
    );
  }

  void _startChat(Listing listing) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create or get existing chat
      final chat = await ref
          .read(createChatProvider.notifier)
          .createChat(
            CreateChatRequest(
              listingId: listing.id,
              listingTitle: listing.title,
              listingImageUrl: listing.imageUrls.isNotEmpty
                  ? listing.imageUrls.first
                  : null,
              listingPrice: listing.price,
              sellerId: listing.sellerId,
              sellerName: listing.sellerName,
              sellerPhotoUrl: listing.sellerPhotoUrl,
            ),
          );

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (chat != null) {
        context.push(AppRoutes.chat.replaceFirst(':id', chat.id));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to start chat')));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showReviewPrompt(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration, color: AppColors.success, size: 48),
        title: const Text('Item Sold!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations on your sale!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Would you like to leave a review for the buyer?',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to create review screen
              // Since we don't know who bought it yet, we'll skip for now
              // In a real app, the buyer would be recorded during the transaction
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'You can leave a review from your chat with the buyer',
                  ),
                ),
              );
            },
            child: const Text('Leave Review'),
          ),
        ],
      ),
    );
  }

  /// Map attribute keys to display labels
  static const _attributeLabelMap = {
    'size': 'Size',
    'size-clothing': 'Size',
    'size-shoes': 'Shoe Size',
    'brand': 'Brand',
    'brand-fashion': 'Brand',
    'brand-consoles': 'Brand',
    'color': 'Color',
    'material': 'Material',
    'storage-capacity': 'Storage',
    'console-model': 'Model',
  };

  /// Build all attribute widgets from JSON
  List<Widget> _buildAdditionalAttributes(Listing listing) {
    if (listing.attributes == null || listing.attributes!.isEmpty) {
      // Return legacy fields if no attributes JSON
      return [
        if (listing.size != null)
          _DetailRow(label: 'Size', value: listing.size!),
        if (listing.brand != null)
          _DetailRow(label: 'Brand', value: listing.brand!),
        if (listing.color != null)
          _DetailRow(label: 'Color', value: listing.color!),
        if (listing.material != null)
          _DetailRow(label: 'Material', value: listing.material!),
      ];
    }

    // Build widgets from all attributes in the JSON
    return listing.attributes!.entries.map((entry) {
      final label =
          _attributeLabelMap[entry.key] ??
          entry.key
              .replaceAll('-', ' ')
              .replaceAll('_', ' ')
              .split(' ')
              .map(
                (word) => word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                    : '',
              )
              .join(' ');
      final value = entry.value is List
          ? (entry.value as List).join(', ')
          : entry.value.toString();
      return _DetailRow(label: label, value: value);
    }).toList();
  }

  void _handleOwnerAction(String action, Listing listing) async {
    switch (action) {
      case 'edit':
        context.push(AppRoutes.editListing.replaceFirst(':id', listing.id));
        break;
      case 'sold':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mark as Sold'),
            content: const Text(
              'Are you sure you want to mark this listing as sold?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Mark Sold'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await ref
              .read(listingActionsProvider(listing.id).notifier)
              .markAsSold();
          ref.invalidate(listingProvider(listing.id));

          if (mounted) {
            // Show review prompt
            _showReviewPrompt(listing);
          }
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Listing'),
            content: const Text(
              'Are you sure you want to delete this listing? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await ref
              .read(listingActionsProvider(listing.id).notifier)
              .deleteListing();
          if (mounted) context.pop();
        }
        break;
    }
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.imageUrls,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
  });

  final List<String> imageUrls;
  final int currentIndex;
  final PageController pageController;
  final void Function(int) onPageChanged;

  void _openFullScreenGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageGallery(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        color: AppColors.gray100,
        child: const Center(
          child: Icon(Icons.image, size: 64, color: AppColors.gray400),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: pageController,
          itemCount: imageUrls.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openFullScreenGallery(context, index),
              child: CachedNetworkImage(
                imageUrl: imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppColors.gray100,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.gray100,
                  child: const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: AppColors.gray400,
                  ),
                ),
              ),
            );
          },
        ),
        // Page indicator
        if (imageUrls.length > 1)
          Positioned(
            bottom: AppSpacing.space4,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == currentIndex
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Full-screen image gallery with pinch-to-zoom
class _FullScreenImageGallery extends StatefulWidget {
  const _FullScreenImageGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FullScreenImageGallery> createState() =>
      _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: AppColors.gray400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.listingId, required this.userId});

  final String listingId;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return IconButton(
        icon: const Icon(Icons.favorite_border),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in to save favorites')),
          );
        },
      );
    }

    final isFavoritedAsync = ref.watch(isFavoritedProvider(listingId));

    return isFavoritedAsync.when(
      loading: () =>
          const IconButton(icon: Icon(Icons.favorite_border), onPressed: null),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.favorite_border),
        onPressed: () => _toggleFavorite(context, ref),
      ),
      data: (isFavorited) => IconButton(
        icon: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_border,
          color: isFavorited ? AppColors.error : null,
        ),
        onPressed: () => _toggleFavorite(context, ref),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, WidgetRef ref) async {
    final isFavorited = await ref
        .read(listingActionsProvider(listingId).notifier)
        .toggleFavorite();

    ref.invalidate(isFavoritedProvider(listingId));
    ref.invalidate(listingProvider(listingId));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorited ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
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
      case ListingStatus.pending:
        backgroundColor = AppColors.gold;
        text = 'Pending Review';
        break;
      case ListingStatus.sold:
        backgroundColor = AppColors.success;
        text = 'Sold';
        break;
      case ListingStatus.rejected:
        backgroundColor = AppColors.error;
        text = 'Rejected';
        break;
      case ListingStatus.archived:
        backgroundColor = AppColors.gray400;
        text = 'Archived';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
