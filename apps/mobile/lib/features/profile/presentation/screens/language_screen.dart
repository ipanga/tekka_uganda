import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../application/language_provider.dart';

/// Screen for selecting app language
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Language'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Info section
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
                    Icons.translate,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Language',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose your preferred language for the Tekka app. This affects menus, buttons, and system messages.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurface,
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

          // Language options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Text(
              'Select Language',
              style: AppTypography.titleMedium,
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          Container(
            color: AppColors.surface,
            child: Column(
              children: AppLanguage.values.map((language) {
                final isSelected = languageState.selectedLanguage == language;

                return _LanguageTile(
                  language: language,
                  isSelected: isSelected,
                  isLoading: languageState.isLoading,
                  onTap: () => _selectLanguage(context, ref, language),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Note about translations
          Padding(
            padding: AppSpacing.screenPadding,
            child: Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.cardRadius,
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        'Note',
                        style: AppTypography.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'Some content like user listings, messages, and reviews will remain in their original language as they are created by other users.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Help improve translations
          Padding(
            padding: AppSpacing.screenPadding,
            child: OutlinedButton.icon(
              onPressed: () => _showTranslationHelp(context),
              icon: const Icon(Icons.volunteer_activism_outlined),
              label: const Text('Help Improve Translations'),
            ),
          ),

          const SizedBox(height: AppSpacing.space10),
        ],
      ),
    );
  }

  Future<void> _selectLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
  ) async {
    final currentLanguage = ref.read(languageProvider).selectedLanguage;

    if (currentLanguage == language) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Language?'),
        content: Text(
          'Change app language to ${language.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(languageProvider.notifier).setLanguage(language);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to ${language.displayName}'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to change language'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showTranslationHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Translate Tekka'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'re always looking to improve our translations and add more languages.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'If you\'d like to help translate Tekka into your language or improve existing translations, please contact us at:',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'translations@tekka.ug',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  final AppLanguage language;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.outline.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            language.flag,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      title: Text(
        language.displayName,
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        language.nativeName,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.white,
                size: 16,
              ),
            )
          : null,
      onTap: isLoading ? null : onTap,
    );
  }
}
