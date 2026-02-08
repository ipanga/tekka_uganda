import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/chat_provider.dart';
import '../../domain/entities/chat.dart';

/// Chat list screen - shows all conversations
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final chatsAsync = ref.watch(chatsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error),
        data: (chats) {
          if (chats.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatsStreamProvider);
            },
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _ChatListItem(
                  chat: chat,
                  currentUserId: user?.uid ?? '',
                  onTap: () {
                    // Mark as read when opening
                    ref
                        .read(chatActionsProvider(chat.id).notifier)
                        .markAsRead();
                    context.push(AppRoutes.chat.replaceFirst(':id', chat.id));
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text('Failed to load messages', style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: () => ref.invalidate(chatsStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
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
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text('No messages yet', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Start a conversation by messaging a seller about an item you like!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Browse Listings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  final Chat chat;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherUserName = chat.getOtherUserName(currentUserId);
    final otherUserPhotoUrl = chat.getOtherUserPhotoUrl(currentUserId);
    final unreadCount = chat.getUnreadCount(currentUserId);
    final lastMessageText = _getLastMessageText();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.screenPadding,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outline, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: AppSpacing.avatarMedium / 2,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: otherUserPhotoUrl != null
                  ? CachedNetworkImageProvider(otherUserPhotoUrl)
                  : null,
              child: otherUserPhotoUrl == null
                  ? Text(
                      otherUserName[0].toUpperCase(),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.space3),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chat.timeAgo,
                        style: AppTypography.bodySmall.copyWith(
                          color: unreadCount > 0
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    chat.listingTitle ?? 'Item',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessageText,
                          style: AppTypography.bodyMedium.copyWith(
                            color: unreadCount > 0
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Listing thumbnail
            const SizedBox(width: AppSpacing.space3),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                image: chat.listingImageUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          chat.listingImageUrl!,
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: chat.listingImageUrl == null
                  ? const Icon(
                      Icons.image,
                      color: AppColors.gray400,
                      size: AppSpacing.iconMedium,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _getLastMessageText() {
    // Use the lastMessageText from the Chat entity (API format)
    return chat.lastMessageText ?? 'No messages yet';
  }
}
