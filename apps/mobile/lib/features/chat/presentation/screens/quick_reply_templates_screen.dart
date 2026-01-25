import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../application/quick_reply_provider.dart';
import '../../domain/entities/quick_reply_template.dart';

/// Screen for managing quick reply templates
class QuickReplyTemplatesScreen extends ConsumerStatefulWidget {
  const QuickReplyTemplatesScreen({super.key});

  @override
  ConsumerState<QuickReplyTemplatesScreen> createState() =>
      _QuickReplyTemplatesScreenState();
}

class _QuickReplyTemplatesScreenState
    extends ConsumerState<QuickReplyTemplatesScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(quickReplyTemplatesStreamProvider);
    final state = ref.watch(quickReplyProvider);

    // Listen for errors
    ref.listen<QuickReplyState>(quickReplyProvider, (prev, next) {
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(quickReplyProvider.notifier).clearError();
      }
    });

    // Listen for success
    ref.listen<QuickReplyState>(quickReplyProvider, (prev, next) {
      if (next.lastOperationSuccess == true &&
          prev?.lastOperationSuccess != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quick Replies'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Reset to defaults'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load templates', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(quickReplyTemplatesStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (templates) {
          final categories = _getCategories(templates);
          final filteredTemplates = _selectedCategory == 'all'
              ? templates
              : templates
                  .where((t) => t.category == _selectedCategory)
                  .toList();

          return Stack(
            children: [
              Column(
                children: [
                  // Category filter
                  if (categories.length > 1)
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space4,
                        vertical: AppSpacing.space2,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(_formatCategory(category)),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _selectedCategory = category);
                                },
                                backgroundColor: AppColors.surface,
                                selectedColor: AppColors.primaryContainer,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  // Templates list
                  Expanded(
                    child: filteredTemplates.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: filteredTemplates.length,
                            itemBuilder: (context, index) {
                              final template = filteredTemplates[index];
                              return _TemplateTile(
                                template: template,
                                onEdit: () => _showEditDialog(template),
                                onDelete: () => _showDeleteConfirm(template),
                              );
                            },
                          ),
                  ),
                ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Template'),
      ),
    );
  }

  List<String> _getCategories(List<QuickReplyTemplate> templates) {
    final categories = <String>{'all'};
    for (final template in templates) {
      if (template.category != null) {
        categories.add(template.category!);
      }
    }
    return categories.toList();
  }

  String _formatCategory(String category) {
    if (category == 'all') return 'All';
    return category.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quickreply_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              'No Templates',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Add quick reply templates to speed up your conversations.',
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reset':
        _showResetConfirm();
        break;
    }
  }

  void _showAddDialog() {
    final textController = TextEditingController();
    String selectedCategory = 'custom';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Enter your quick reply...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text('Category', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: 8,
                children: [
                  _CategoryChip(
                    label: 'Custom',
                    value: 'custom',
                    selected: selectedCategory,
                    onSelected: (v) => setDialogState(() => selectedCategory = v),
                  ),
                  _CategoryChip(
                    label: 'Availability',
                    value: 'availability',
                    selected: selectedCategory,
                    onSelected: (v) => setDialogState(() => selectedCategory = v),
                  ),
                  _CategoryChip(
                    label: 'Negotiation',
                    value: 'negotiation',
                    selected: selectedCategory,
                    onSelected: (v) => setDialogState(() => selectedCategory = v),
                  ),
                  _CategoryChip(
                    label: 'Meetup',
                    value: 'meetup',
                    selected: selectedCategory,
                    onSelected: (v) => setDialogState(() => selectedCategory = v),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  ref.read(quickReplyProvider.notifier).addTemplate(
                        textController.text,
                        category: selectedCategory,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(QuickReplyTemplate template) {
    final textController = TextEditingController(text: template.text);
    String selectedCategory = template.category ?? 'custom';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Enter your quick reply...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text('Category', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: 8,
                children: [
                  _CategoryChip(
                    label: 'Custom',
                    value: 'custom',
                    selected: selectedCategory,
                    onSelected: (v) => setDialogState(() => selectedCategory = v),
                  ),
                  _CategoryChip(
                    label: 'Availability',
                    value: 'availability',
                    selected: selectedCategory,
                    onSelected: (v) => setDialogState(() => selectedCategory = v),
                  ),
                  _CategoryChip(
                    label: 'Negotiation',
                    value: 'negotiation',
                    selected: selectedCategory,
                    onSelected: (v) => setDialogState(() => selectedCategory = v),
                  ),
                  _CategoryChip(
                    label: 'Meetup',
                    value: 'meetup',
                    selected: selectedCategory,
                    onSelected: (v) => setDialogState(() => selectedCategory = v),
                  ),
                ],
              ),
              if (template.usageCount > 0) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Used ${template.usageCount} times',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  ref.read(quickReplyProvider.notifier).updateTemplate(
                        template.id,
                        textController.text,
                        category: selectedCategory,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(QuickReplyTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Delete "${template.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(quickReplyProvider.notifier).deleteTemplate(template.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Templates'),
        content: const Text(
          'This will delete all your custom templates and restore the default ones. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(quickReplyProvider.notifier).resetToDefaults();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  final QuickReplyTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(template.id),
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
      child: ListTile(
        onTap: onEdit,
        title: Text(
          template.text,
          style: AppTypography.bodyLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatCategory(template.category ?? 'custom'),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            if (template.usageCount > 0) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.history,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${template.usageCount}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            if (template.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Default',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selected;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryContainer,
    );
  }
}
