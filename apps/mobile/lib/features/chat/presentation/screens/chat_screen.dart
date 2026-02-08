import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/image_service_provider.dart' as services;
import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../meetup/presentation/widgets/schedule_meetup_sheet.dart';
import '../../../reviews/application/review_provider.dart';
import '../../../reviews/domain/entities/review.dart';
import '../../application/chat_provider.dart';
import '../../application/quick_reply_provider.dart';
import '../../domain/entities/chat.dart';

/// Individual chat conversation screen
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
  });

  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatActionsProvider(widget.chatId).notifier).markAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final chatAsync = ref.watch(chatProvider(widget.chatId));
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatId));
    final chatActions = ref.watch(chatActionsProvider(widget.chatId));
    final typingStatus = ref.watch(typingStatusProvider(widget.chatId));

    // Listen for errors
    ref.listen<ChatActionsState>(chatActionsProvider(widget.chatId), (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(chatActionsProvider(widget.chatId).notifier).clearError();
      }
      if (next.isDeleted) {
        context.pop();
      }
    });

    return chatAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load chat', style: AppTypography.bodyLarge),
              TextButton(
                onPressed: () => ref.invalidate(chatProvider(widget.chatId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (chat) {
        if (chat == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Chat not found')),
          );
        }

        final currentUserId = user?.uid ?? '';
        final otherUserName = chat.getOtherUserName(currentUserId);
        final otherUserPhotoUrl = chat.getOtherUserPhotoUrl(currentUserId);
        final otherUserId = chat.getOtherUserId(currentUserId);

        // Check if other user is typing
        final isOtherTyping = typingStatus.maybeWhen(
          data: (status) => status[otherUserId] ?? false,
          orElse: () => false,
        );

        // Check if chat is blocked
        final isChatBlockedAsync = ref.watch(isChatBlockedProvider(otherUserId));
        final isChatBlocked = isChatBlockedAsync.maybeWhen(
          data: (blocked) => blocked,
          orElse: () => false,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: otherUserPhotoUrl != null
                      ? CachedNetworkImageProvider(otherUserPhotoUrl)
                      : null,
                  child: otherUserPhotoUrl == null
                      ? Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUserName,
                        style: AppTypography.labelLarge,
                      ),
                      if (isOtherTyping)
                        Text(
                          'typing...',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(value, chat, otherUserId),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view_listing',
                    child: Text('View Listing'),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Report'),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Text('Block User'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Chat'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Listing context bar
              _ListingContextBar(chat: chat),
              const Divider(height: 1),

              // Blocked banner
              if (isChatBlocked)
                _BlockedBanner(otherUserName: otherUserName),

              // Review banner for sold listings
              if (!isChatBlocked)
                _ReviewBanner(
                  chat: chat,
                  currentUserId: currentUserId,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                ),

              // Messages list
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => const Center(
                    child: Text('Failed to load messages'),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return _buildEmptyMessages();
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.screenPadding,
                      reverse: false,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final showDateSeparator = index == 0 ||
                            messages[index].dateGroup != messages[index - 1].dateGroup;

                        return Column(
                          children: [
                            if (showDateSeparator) ...[
                              if (index > 0) const SizedBox(height: AppSpacing.space4),
                              _DateSeparator(date: message.dateGroup),
                              const SizedBox(height: AppSpacing.space4),
                            ],
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                              child: _MessageBubble(
                                message: message,
                                isMe: message.isFromMe(currentUserId),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Quick actions (hide when blocked)
              if (!isChatBlocked)
                _QuickActionsBar(
                  onQuickMessage: _sendQuickMessage,
                ),

              // Message input or blocked message
              if (isChatBlocked)
                _BlockedMessageInput()
              else
                _MessageInput(
                  controller: _messageController,
                  isSending: chatActions.isSending || chatActions.isUploadingImage,
                  onSend: _sendMessage,
                  onTyping: () {
                    ref.read(chatActionsProvider(widget.chatId).notifier).setTyping(true);
                  },
                  onSuggestMeetup: () => _suggestMeetup(chat),
                  onSendPhoto: _sendPhoto,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Start the conversation!',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Send a message to get started',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    ref.read(chatActionsProvider(widget.chatId).notifier).sendMessage(
          _messageController.text,
        );
    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendQuickMessage(String message, String? templateId) {
    ref.read(chatActionsProvider(widget.chatId).notifier).sendMessage(message);

    // Record usage if template ID is provided
    if (templateId != null) {
      ref.read(quickReplyProvider.notifier).recordUsage(templateId);
    }

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _suggestMeetup(Chat chat) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final meetup = await showScheduleMeetupSheet(
      context,
      chatId: chat.id,
      listingId: chat.listingId,
      buyerId: chat.buyerId,
      sellerId: chat.sellerId,
    );

    if (meetup != null) {
      // Send a meetup message to the chat
      final message = 'Meetup proposed at ${meetup.location.name} on ${meetup.formattedDate} at ${meetup.formattedTime}';
      ref.read(chatActionsProvider(widget.chatId).notifier).sendMessage(
        message,
        type: MessageType.meetup,
        meetupData: meetup.toMap(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meetup proposal sent!')),
        );
      }
    }
  }

  Future<void> _sendPhoto() async {
    final imageService = ref.read(services.imageServiceProvider);
    final storageService = ref.read(services.storageServiceProvider);

    // Show picker options
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Pick image
    final imageFile = source == 'camera'
        ? await imageService.takePhoto()
        : await imageService.pickImageFromGallery();

    if (imageFile == null) return;

    // Compress image
    final compressedFile = await imageService.compressImage(imageFile);
    if (compressedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process image')),
        );
      }
      return;
    }

    // Upload image
    ref.read(chatActionsProvider(widget.chatId).notifier).setUploadingImage(true);

    try {
      final imageUrl = await storageService.uploadChatImage(
        imageFile: compressedFile,
        chatId: widget.chatId,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Send image message
      ref.read(chatActionsProvider(widget.chatId).notifier).sendMessage(
        '',
        type: MessageType.image,
        imageUrl: imageUrl,
      );

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      ref.read(chatActionsProvider(widget.chatId).notifier).setUploadingImage(false);
      // Clean up temp file
      imageService.cleanupTempFiles([compressedFile]);
    }
  }

  void _handleMenuAction(String action, Chat chat, String otherUserId) async {
    switch (action) {
      case 'view_listing':
        context.push(AppRoutes.listingDetail.replaceFirst(':id', chat.listingId));
        break;
      case 'report':
        _showReportDialog();
        break;
      case 'block':
        _showBlockConfirmation(otherUserId);
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this conversation?'),
            const SizedBox(height: 16),
            ...[
              'Spam or scam',
              'Harassment',
              'Inappropriate content',
              'Other',
            ].map((reason) {
              return ListTile(
                title: Text(reason),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(chatActionsProvider(widget.chatId).notifier).reportChat(reason);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted. Thank you!')),
                  );
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user? You will no longer receive messages from them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatActionsProvider(widget.chatId).notifier).blockUser(userId);
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatActionsProvider(widget.chatId).notifier).deleteChat();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ListingContextBar extends StatelessWidget {
  const _ListingContextBar({required this.chat});

  final Chat chat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              image: chat.listingImageUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(chat.listingImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: chat.listingImageUrl == null
                ? const Icon(
                    Icons.image,
                    color: AppColors.gray400,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.listingTitle ?? 'Item',
                  style: AppTypography.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'UGX ${_formatPrice(chat.listingPrice ?? 0)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              context.push(AppRoutes.listingDetail.replaceFirst(':id', chat.listingId));
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)},000';
    }
    return price.toString();
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          date,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  final Message message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: AppSpacing.chatBubblePadding,
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusMd),
            topRight: const Radius.circular(AppSpacing.radiusMd),
            bottomLeft: Radius.circular(isMe ? AppSpacing.radiusMd : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppSpacing.radiusMd),
          ),
          border: isMe ? null : Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildMessageContent(),
            const SizedBox(height: AppSpacing.space1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.formattedTime,
                  style: AppTypography.bodySmall.copyWith(
                    color: isMe
                        ? AppColors.white.withValues(alpha: 0.7)
                        : AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.offer:
        // Legacy offer messages - display as text
        return Text(
          message.content.isNotEmpty ? message.content : 'Sent an offer',
          style: AppTypography.bodyMedium.copyWith(
            color: isMe ? AppColors.white : AppColors.onSurface,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: AppTypography.bodyMedium.copyWith(
                  color: isMe ? AppColors.white : AppColors.onSurface,
                ),
              ),
            ],
          ],
        );
      case MessageType.system:
        return Text(
          message.content,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        );
      case MessageType.meetup:
        return _buildMeetupContent();
      case MessageType.text:
        return Text(
          message.content,
          style: AppTypography.bodyMedium.copyWith(
            color: isMe ? AppColors.white : AppColors.onSurface,
          ),
        );
    }
  }

  Widget _buildMeetupContent() {
    final meetupData = message.meetupData;
    String locationName = 'Unknown Location';
    String date = '';
    String time = '';

    if (meetupData != null) {
      final location = meetupData['location'] as Map<String, dynamic>?;
      locationName = location?['name'] as String? ?? 'Unknown Location';

      final scheduledAt = meetupData['scheduledAt'] as String?;
      if (scheduledAt != null) {
        final dateTime = DateTime.parse(scheduledAt);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        date = '${months[dateTime.month - 1]} ${dateTime.day}';
        final hour = dateTime.hour;
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        time = '$displayHour:$minute $period';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: isMe ? AppColors.white.withValues(alpha: 0.8) : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Meetup Proposal',
              style: AppTypography.labelSmall.copyWith(
                color: isMe ? AppColors.white.withValues(alpha: 0.8) : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          locationName,
          style: AppTypography.titleSmall.copyWith(
            color: isMe ? AppColors.white : AppColors.onSurface,
          ),
        ),
        if (date.isNotEmpty || time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isMe ? AppColors.white.withValues(alpha: 0.7) : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '$date at $time',
                style: AppTypography.bodySmall.copyWith(
                  color: isMe ? AppColors.white.withValues(alpha: 0.8) : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color = AppColors.white.withValues(alpha: 0.7);

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
      case MessageStatus.sent:
        icon = Icons.check;
      case MessageStatus.delivered:
        icon = Icons.done_all;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = AppColors.success;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = AppColors.error;
    }

    return Icon(icon, size: 14, color: color);
  }
}

class _QuickActionsBar extends ConsumerWidget {
  const _QuickActionsBar({
    required this.onQuickMessage,
  });

  final void Function(String, String?) onQuickMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(quickReplyTemplatesStreamProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: templatesAsync.when(
        loading: () => const SizedBox(height: 36),
        error: (_, _) => _buildDefaultChips(),
        data: (templates) {
          if (templates.isEmpty) {
            return _buildDefaultChips();
          }

          // Show first 5 templates sorted by usage
          final displayTemplates = templates.take(5).toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...displayTemplates.map((template) {
                  final index = displayTemplates.indexOf(template);
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < displayTemplates.length - 1
                          ? AppSpacing.space2
                          : 0,
                    ),
                    child: _QuickActionChip(
                      label: template.text.length > 20
                          ? '${template.text.substring(0, 20)}...'
                          : template.text,
                      onTap: () => onQuickMessage(template.text, template.id),
                    ),
                  );
                }),
                const SizedBox(width: AppSpacing.space2),
                _QuickActionChip(
                  label: 'More...',
                  icon: Icons.more_horiz,
                  onTap: () => _showAllTemplates(context, ref, templates),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickActionChip(
            label: 'Is this available?',
            onTap: () => onQuickMessage('Is this still available?', null),
          ),
          const SizedBox(width: AppSpacing.space2),
          _QuickActionChip(
            label: "What's the lowest?",
            onTap: () => onQuickMessage("What's your lowest price?", null),
          ),
          const SizedBox(width: AppSpacing.space2),
          _QuickActionChip(
            label: 'Can we meet?',
            onTap: () => onQuickMessage('Can we arrange a meetup?', null),
          ),
        ],
      ),
    );
  }

  void _showAllTemplates(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> templates,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Replies',
                    style: AppTypography.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.quickReplyTemplates);
                    },
                    child: const Text('Manage'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return ListTile(
                    title: Text(
                      template.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: template.category != null
                        ? Text(
                            _formatCategory(template.category!),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: template.usageCount > 0
                        ? Text(
                            '${template.usageCount}x',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onQuickMessage(template.text, template.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCategory(String category) {
    return category.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onTyping,
    required this.onSuggestMeetup,
    required this.onSendPhoto,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onTyping;
  final VoidCallback onSuggestMeetup;
  final VoidCallback onSendPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppTheme.stickyShadow,
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.onSurfaceVariant,
              onPressed: () => _showAttachmentOptions(context),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onChanged: (_) => onTyping(),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              color: AppColors.primary,
              onPressed: isSending ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: AppColors.primary),
              ),
              title: const Text('Suggest Meetup'),
              subtitle: const Text('Propose a safe meeting location'),
              onTap: () {
                Navigator.pop(context);
                onSuggestMeetup();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo, color: AppColors.secondary),
              ),
              title: const Text('Send Photo'),
              subtitle: const Text('Share an image'),
              onTap: () {
                Navigator.pop(context);
                onSendPhoto();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner shown in chat when listing is sold to prompt for review
class _ReviewBanner extends ConsumerWidget {
  const _ReviewBanner({
    required this.chat,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  final Chat chat;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingProvider(chat.listingId));

    return listingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (listing) {
        if (listing == null || listing.status != ListingStatus.sold) {
          return const SizedBox.shrink();
        }

        // Check if current user can leave a review
        final canReviewAsync = ref.watch(canReviewProvider(CanReviewParams(
          revieweeId: otherUserId,
          listingId: chat.listingId,
        )));

        return canReviewAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (canReview) {
            if (!canReview) {
              return const SizedBox.shrink();
            }

            // Determine review type based on who is viewing
            final isSeller = listing.sellerId == currentUserId;
            final reviewType = isSeller ? ReviewType.buyer : ReviewType.seller;

            return Container(
              padding: AppSpacing.cardPadding,
              color: AppColors.success.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      'Transaction complete! Leave a review for $otherUserName',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push(
                        AppRoutes.createReview,
                        extra: {
                          'revieweeId': otherUserId,
                          'revieweeName': otherUserName,
                          'listingId': chat.listingId,
                          'listingTitle': chat.listingTitle,
                          'reviewType': reviewType,
                        },
                      );
                    },
                    child: const Text('Review'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Banner shown when chat is blocked
class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner({required this.otherUserName});

  final String otherUserName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      color: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            Icons.block,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              'You can no longer send messages to $otherUserName',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Disabled message input shown when blocked
class _BlockedMessageInput extends StatelessWidget {
  const _BlockedMessageInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        boxShadow: AppTheme.stickyShadow,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  'You cannot reply to this conversation',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
