import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/account_deletion_provider.dart';

/// Screen for account deletion with confirmation flow
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState
    extends ConsumerState<AccountDeletionScreen> {
  DeletionReason? _selectedReason;
  final _otherReasonController = TextEditingController();
  bool _confirmChecked = false;
  bool _understandChecked = false;

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(accountDeletionProvider);
    final user = ref.watch(currentUserProvider);

    // Listen for state changes
    ref.listen<AccountDeletionStatus>(accountDeletionProvider, (prev, next) {
      if (next.state == AccountDeletionState.deleted) {
        // Account deleted, navigate to login
        context.go(AppRoutes.phoneInput);
      }
      if (next.state == AccountDeletionState.scheduledForDeletion &&
          prev?.state != AccountDeletionState.scheduledForDeletion) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account scheduled for deletion'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: SafeArea(
        child: status.isScheduled
            ? _buildScheduledView(status)
            : _buildDeletionForm(status, user),
      ),
    );
  }

  Widget _buildScheduledView(AccountDeletionStatus status) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule,
                size: 60,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              'Deletion Scheduled',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Your account is scheduled for deletion in ${status.daysUntilDeletion} days.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space4),
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.cardRadius,
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: AppSpacing.space3),
                      Text(
                        'Deletion date',
                        style: AppTypography.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(status.scheduledDeletionDate!),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'You can cancel the deletion at any time before this date. After this date, your account and all data will be permanently deleted.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _cancelDeletion,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Cancel Deletion'),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletionForm(AccountDeletionStatus status, dynamic user) {
    final isLoading = status.state == AccountDeletionState.deleting ||
        status.state == AccountDeletionState.confirming;

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.space4),

        // Warning header
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This action cannot be undone',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deleting your account will permanently remove all your data, listings, messages, and reviews.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // What will be deleted
        Text(
          'What will be deleted:',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.space3),
        _DeletionItem(text: 'Your profile and account information'),
        _DeletionItem(text: 'All your active and sold listings'),
        _DeletionItem(text: 'Your chat messages and conversations'),
        _DeletionItem(text: 'Reviews you have written and received'),
        _DeletionItem(text: 'Your saved items and preferences'),
        _DeletionItem(text: 'Offers and transaction history'),

        const SizedBox(height: AppSpacing.space6),

        // Reason selection
        Text(
          'Why are you leaving?',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'This helps us improve our service (optional)',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        ...DeletionReason.values.map((reason) => RadioListTile<DeletionReason>(
              title: Text(reason.displayName),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() => _selectedReason = value);
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),

        if (_selectedReason == DeletionReason.other) ...[
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: _otherReasonController,
            decoration: const InputDecoration(
              hintText: 'Please tell us more...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],

        const SizedBox(height: AppSpacing.space6),

        // Confirmation checkboxes
        CheckboxListTile(
          value: _understandChecked,
          onChanged: (value) {
            setState(() => _understandChecked = value ?? false);
          },
          title: Text(
            'I understand that my data will be permanently deleted and cannot be recovered',
            style: AppTypography.bodyMedium,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),

        CheckboxListTile(
          value: _confirmChecked,
          onChanged: (value) {
            setState(() => _confirmChecked = value ?? false);
          },
          title: Text(
            'I confirm that I want to delete my account',
            style: AppTypography.bodyMedium,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),

        if (status.state == AccountDeletionState.error &&
            status.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space4),
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    status.errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.space6),

        // Action buttons
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canDelete && !isLoading
                ? () => _showDeleteConfirmation(context)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Delete My Account'),
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : () => context.pop(),
            child: const Text('Cancel'),
          ),
        ),

        const SizedBox(height: AppSpacing.space8),
      ],
    );
  }

  bool get _canDelete => _confirmChecked && _understandChecked;

  String get _reasonText {
    if (_selectedReason == null) return 'No reason provided';
    if (_selectedReason == DeletionReason.other) {
      return _otherReasonController.text.isNotEmpty
          ? _otherReasonController.text
          : 'Other (no details)';
    }
    return _selectedReason!.displayName;
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how you want to delete your account:',
            ),
            const SizedBox(height: 16),
            Text(
              'Option 1: Schedule Deletion',
              style: AppTypography.titleSmall,
            ),
            Text(
              'Your account will be deleted in 7 days. You can cancel anytime before then.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Option 2: Delete Immediately',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.error,
              ),
            ),
            Text(
              'Your account will be deleted right now. This cannot be undone.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _scheduleAccountDeletion();
            },
            child: const Text('Schedule (7 days)'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccountImmediately();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleAccountDeletion() async {
    await ref.read(accountDeletionProvider.notifier).scheduleAccountDeletion(
          reason: _reasonText,
          gracePeriodDays: 7,
        );
  }

  Future<void> _deleteAccountImmediately() async {
    final success = await ref
        .read(accountDeletionProvider.notifier)
        .deleteAccountImmediately();

    if (!success && mounted) {
      final status = ref.read(accountDeletionProvider);
      if (status.requiresReauth) {
        _showReauthDialog();
      }
    }
  }

  Future<void> _cancelDeletion() async {
    final success =
        await ref.read(accountDeletionProvider.notifier).cancelScheduledDeletion();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion cancelled'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showReauthDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-authentication Required'),
        content: const Text(
          'For security reasons, please sign out and sign back in, then try deleting your account again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _DeletionItem extends StatelessWidget {
  final String text;

  const _DeletionItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.remove_circle_outline,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
