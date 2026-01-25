import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/theme.dart';
import '../../application/data_export_provider.dart';

/// Screen for exporting user data (GDPR compliance)
class DataExportScreen extends ConsumerWidget {
  const DataExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(dataExportProvider);

    // Listen for errors
    ref.listen<DataExportState>(dataExportProvider, (prev, next) {
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(dataExportProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export Your Data'),
      ),
      body: exportState.isExporting
          ? _buildExportingView(exportState)
          : exportState.hasExport
              ? _buildExportReadyView(context, ref, exportState)
              : _buildSelectionView(context, ref, exportState),
    );
  }

  Widget _buildSelectionView(
    BuildContext context,
    WidgetRef ref,
    DataExportState state,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: AppSpacing.space4),

              // Info header
              Padding(
                padding: AppSpacing.screenPadding,
                child: Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: AppSpacing.cardRadius,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 24,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Download Your Data',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Get a copy of your personal data stored in Tekka. '
                              'Select what data you want to include in your export.',
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
              ),

              const SizedBox(height: AppSpacing.space4),

              // Select all / Deselect all
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DATA TO EXPORT',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () =>
                              ref.read(dataExportProvider.notifier).selectAll(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Select All'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () =>
                              ref.read(dataExportProvider.notifier).deselectAll(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Deselect All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.space2),

              // Data type options
              Container(
                color: AppColors.surface,
                child: Column(
                  children: ExportDataType.values.map((type) {
                    return _DataTypeOption(
                      type: type,
                      isSelected: state.selectedTypes.contains(type),
                      onToggle: () =>
                          ref.read(dataExportProvider.notifier).toggleDataType(type),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Privacy note
              Padding(
                padding: AppSpacing.screenPadding,
                child: Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.cardRadius,
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(
                          'Your data will be exported as a JSON file. '
                          'Keep this file secure as it contains personal information.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space10),
            ],
          ),
        ),

        // Export button
        Container(
          padding: AppSpacing.screenPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.outline),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.selectedTypes.isNotEmpty
                    ? () => ref.read(dataExportProvider.notifier).startExport()
                    : null,
                icon: const Icon(Icons.download),
                label: Text(
                  'Export ${state.selectedTypes.length} Data Types',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportingView(DataExportState state) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress indicator
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: state.progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.outline,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Text(
                    '${(state.progress * 100).toInt()}%',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space6),

            Text(
              state.status == DataExportStatus.collecting
                  ? 'Collecting Your Data'
                  : 'Packaging Your Data',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppSpacing.space2),

            if (state.currentStep != null)
              Text(
                state.currentStep!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: AppSpacing.space4),

            Text(
              'Please wait, this may take a moment...',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportReadyView(
    BuildContext context,
    WidgetRef ref,
    DataExportState state,
  ) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: AppColors.success,
              ),
            ),

            const SizedBox(height: AppSpacing.space6),

            Text(
              'Export Ready!',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSpacing.space2),

            Text(
              'Your data has been exported successfully.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            if (state.exportDate != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Generated on ${_formatDate(state.exportDate!)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.space8),

            // Share button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _shareExport(state.exportFilePath!),
                icon: const Icon(Icons.share),
                label: const Text('Share Export File'),
              ),
            ),

            const SizedBox(height: AppSpacing.space3),

            // New export button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(dataExportProvider.notifier).deleteExport(),
                icon: const Icon(Icons.refresh),
                label: const Text('Create New Export'),
              ),
            ),

            const SizedBox(height: AppSpacing.space6),

            // File info
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'tekka_data_export.json',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'JSON File',
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _shareExport(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'My Tekka Data Export',
        text: 'Here is my exported data from Tekka.',
      );
    } catch (e) {
      // Handle share error silently
    }
  }
}

class _DataTypeOption extends StatelessWidget {
  const _DataTypeOption({
    required this.type,
    required this.isSelected,
    required this.onToggle,
  });

  final ExportDataType type;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _getIcon(type),
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
      title: Text(
        type.displayName,
        style: AppTypography.bodyLarge,
      ),
      subtitle: Text(
        type.description,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) => onToggle(),
        activeColor: AppColors.primary,
      ),
      onTap: onToggle,
    );
  }

  IconData _getIcon(ExportDataType type) {
    switch (type) {
      case ExportDataType.profile:
        return Icons.person_outline;
      case ExportDataType.listings:
        return Icons.sell_outlined;
      case ExportDataType.purchases:
        return Icons.shopping_bag_outlined;
      case ExportDataType.sales:
        return Icons.payments_outlined;
      case ExportDataType.favorites:
        return Icons.favorite_outline;
      case ExportDataType.messages:
        return Icons.chat_bubble_outline;
      case ExportDataType.reviews:
        return Icons.star_outline;
      case ExportDataType.searchHistory:
        return Icons.history;
      case ExportDataType.activityLog:
        return Icons.list_alt;
    }
  }
}
