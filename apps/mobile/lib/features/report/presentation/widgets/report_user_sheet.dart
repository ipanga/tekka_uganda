import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../application/report_provider.dart';
import '../../domain/entities/report.dart';

/// Shows a bottom sheet to report a user
Future<bool?> showReportUserSheet(
  BuildContext context, {
  required String reportedUserId,
  required String reportedUserName,
  String? listingId,
  String? chatId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ReportUserSheet(
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      listingId: listingId,
      chatId: chatId,
    ),
  );
}

class _ReportUserSheet extends ConsumerStatefulWidget {
  const _ReportUserSheet({
    required this.reportedUserId,
    required this.reportedUserName,
    this.listingId,
    this.chatId,
  });

  final String reportedUserId;
  final String reportedUserName;
  final String? listingId;
  final String? chatId;

  @override
  ConsumerState<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends ConsumerState<_ReportUserSheet> {
  ReportReason? _selectedReason;
  final _detailsController = TextEditingController();
  bool _blockUser = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportActionsProvider);

    ref.listen<ReportActionsState>(reportActionsProvider, (prev, next) {
      if (next.isSuccess && prev?.isSuccess != true) {
        Navigator.pop(context, true);
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Report ${widget.reportedUserName}',
                        style: AppTypography.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  children: [
                    // Info text
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.space2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.onWarningContainer,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.space3),
                          Expanded(
                            child: Text(
                              'Reports are reviewed by our team within 24 hours. False reports may result in account restrictions.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onWarningContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Reason selection
                    Text(
                      'Why are you reporting this user?',
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.space3),

                    ...ReportReason.values.map(
                      (reason) => _ReasonTile(
                        reason: reason,
                        isSelected: _selectedReason == reason,
                        onTap: () {
                          setState(() {
                            _selectedReason = reason;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Additional details
                    Text(
                      'Additional details (optional)',
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    TextField(
                      controller: _detailsController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            'Provide any additional context that might help us review this report...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.space2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.space4),

                    // Block option
                    CheckboxListTile(
                      value: _blockUser,
                      onChanged: (value) {
                        setState(() {
                          _blockUser = value ?? false;
                        });
                      },
                      title: Text(
                        'Also block this user',
                        style: AppTypography.bodyMedium,
                      ),
                      subtitle: Text(
                        'They won\'t be able to contact you or see your listings',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: AppSpacing.space6),
                  ],
                ),
              ),

              // Submit button
              Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: AppTheme.stickyShadow,
                ),
                child: SafeArea(
                  child: FilledButton(
                    onPressed: _selectedReason == null || state.isLoading
                        ? null
                        : _submitReport,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppColors.error,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Report'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    final notifier = ref.read(reportActionsProvider.notifier);

    // Submit report
    final report = await notifier.submitReport(
      CreateReportRequest(
        reportedUserId: widget.reportedUserId,
        reportedUserName: widget.reportedUserName,
        reason: _selectedReason!,
        additionalDetails: _detailsController.text.trim().isEmpty
            ? null
            : _detailsController.text.trim(),
        listingId: widget.listingId,
        chatId: widget.chatId,
      ),
    );

    // Block user if selected
    if (report != null && _blockUser) {
      await notifier.blockUser(widget.reportedUserId);
    }
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.space2),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        margin: const EdgeInsets.only(bottom: AppSpacing.space2),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.space2),
          color: isSelected ? AppColors.primaryContainer : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    reason.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
