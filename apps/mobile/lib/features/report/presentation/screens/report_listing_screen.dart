import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../application/report_provider.dart';
import '../../domain/entities/report.dart';

/// Listing-specific report reasons
enum ListingReportReason {
  prohibited,
  counterfeit,
  misleading,
  wrongCategory,
  spam,
  other,
}

extension ListingReportReasonExtension on ListingReportReason {
  String get displayName {
    switch (this) {
      case ListingReportReason.prohibited:
        return 'Prohibited item';
      case ListingReportReason.counterfeit:
        return 'Counterfeit or fake';
      case ListingReportReason.misleading:
        return 'Misleading description';
      case ListingReportReason.wrongCategory:
        return 'Wrong category';
      case ListingReportReason.spam:
        return 'Spam or duplicate';
      case ListingReportReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ListingReportReason.prohibited:
        return 'Items that are not allowed on Tekka (weapons, drugs, etc.)';
      case ListingReportReason.counterfeit:
        return 'Item appears to be fake or a replica sold as authentic';
      case ListingReportReason.misleading:
        return 'Description doesn\'t match the item or contains false claims';
      case ListingReportReason.wrongCategory:
        return 'Item is listed in the wrong category';
      case ListingReportReason.spam:
        return 'Same item listed multiple times or promotional content';
      case ListingReportReason.other:
        return 'Other issue not listed above';
    }
  }

  ReportReason toReportReason() {
    switch (this) {
      case ListingReportReason.prohibited:
        return ReportReason.inappropriateContent;
      case ListingReportReason.counterfeit:
        return ReportReason.counterfeitItems;
      case ListingReportReason.misleading:
        return ReportReason.scam;
      case ListingReportReason.wrongCategory:
        return ReportReason.other;
      case ListingReportReason.spam:
        return ReportReason.spam;
      case ListingReportReason.other:
        return ReportReason.other;
    }
  }
}

/// Screen for reporting a listing
class ReportListingScreen extends ConsumerStatefulWidget {
  final String listingId;
  final String listingTitle;
  final String sellerId;
  final String sellerName;

  const ReportListingScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  ConsumerState<ReportListingScreen> createState() => _ReportListingScreenState();
}

class _ReportListingScreenState extends ConsumerState<ReportListingScreen> {
  ListingReportReason? _selectedReason;
  final _detailsController = TextEditingController();
  bool _blockSeller = false;

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
        _showSuccessDialog();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Listing'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing info card
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.cardRadius,
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.listingTitle,
                                style: AppTypography.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${widget.sellerName}',
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

                  const SizedBox(height: AppSpacing.space6),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                            'Reports are reviewed within 24 hours. If the listing violates our policies, it will be removed.',
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
                    'What\'s wrong with this listing?',
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  ...ListingReportReason.values.map((reason) => _ReasonTile(
                        reason: reason,
                        isSelected: _selectedReason == reason,
                        onTap: () {
                          setState(() {
                            _selectedReason = reason;
                          });
                        },
                      )),

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
                      hintText: 'Provide more context about this issue...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space4),

                  // Block seller option
                  CheckboxListTile(
                    value: _blockSeller,
                    onChanged: (value) {
                      setState(() {
                        _blockSeller = value ?? false;
                      });
                    },
                    title: Text(
                      'Also block this seller',
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
          ),

          // Submit button
          Container(
            padding: AppSpacing.screenPadding,
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
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    final notifier = ref.read(reportActionsProvider.notifier);

    // Submit report
    final report = await notifier.submitReport(
      CreateReportRequest(
        reportedUserId: widget.sellerId,
        reportedUserName: widget.sellerName,
        reason: _selectedReason!.toReportReason(),
        additionalDetails: _detailsController.text.trim().isEmpty
            ? '${_selectedReason!.displayName}: ${_selectedReason!.description}'
            : '${_selectedReason!.displayName}: ${_detailsController.text.trim()}',
        listingId: widget.listingId,
      ),
    );

    // Block seller if selected
    if (report != null && _blockSeller) {
      await notifier.blockUser(widget.sellerId);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Report Submitted'),
          ],
        ),
        content: const Text(
          'Thank you for helping keep Tekka safe. Our team will review this report and take appropriate action.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Go back
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final ListingReportReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        margin: const EdgeInsets.only(bottom: AppSpacing.space2),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          color: isSelected ? AppColors.primaryContainer : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
