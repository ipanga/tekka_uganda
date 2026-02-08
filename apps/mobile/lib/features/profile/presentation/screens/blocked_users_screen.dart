import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../report/application/report_provider.dart';

/// Provider for blocked users with their details
/// Uses the API-based blockedUsersProvider which returns full AppUser objects
final blockedUsersWithDetailsProvider = FutureProvider<List<BlockedUserInfo>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  // Use the API-based blocked users provider which returns full user objects
  final blockedAppUsers = await ref.watch(blockedUsersProvider.future);

  return blockedAppUsers
      .map(
        (appUser) => BlockedUserInfo(
          id: appUser.uid,
          displayName: appUser.displayName ?? 'Unknown User',
          photoUrl: appUser.photoUrl,
        ),
      )
      .toList();
});

/// Blocked user info
class BlockedUserInfo {
  final String id;
  final String displayName;
  final String? photoUrl;

  const BlockedUserInfo({
    required this.id,
    required this.displayName,
    this.photoUrl,
  });
}

/// Screen to view and manage blocked users
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersWithDetailsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Blocked Users')),
      body: blockedUsersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Failed to load blocked users',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () =>
                    ref.invalidate(blockedUsersWithDetailsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (blockedUsers) {
          if (blockedUsers.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return _BlockedUserTile(
                user: user,
                onUnblock: () => _showUnblockDialog(context, ref, user),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text('No blocked users', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.space2),
            Text(
              "You haven't blocked anyone yet. Blocked users won't be able to contact you or see your listings.",
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

  void _showUnblockDialog(
    BuildContext context,
    WidgetRef ref,
    BlockedUserInfo user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock ${user.displayName}?'),
        content: const Text(
          'They will be able to contact you and see your listings again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _unblockUser(context, ref, user);
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(
    BuildContext context,
    WidgetRef ref,
    BlockedUserInfo user,
  ) async {
    final notifier = ref.read(reportActionsProvider.notifier);
    await notifier.unblockUser(user.id);

    // Refresh the list
    ref.invalidate(blockedUsersWithDetailsProvider);
    ref.invalidate(blockedUsersProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.displayName} has been unblocked')),
      );
    }
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({required this.user, required this.onUnblock});

  final BlockedUserInfo user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryContainer,
        backgroundImage: user.photoUrl != null
            ? NetworkImage(user.photoUrl!)
            : null,
        child: user.photoUrl == null
            ? Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
      title: Text(user.displayName, style: AppTypography.bodyLarge),
      trailing: OutlinedButton(
        onPressed: onUnblock,
        child: const Text('Unblock'),
      ),
    );
  }
}
