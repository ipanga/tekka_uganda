import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/privacy_provider.dart';
import '../../domain/entities/privacy_preferences.dart';

/// Privacy settings screen
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(privacyPreferencesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load settings', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () =>
                    ref.invalidate(privacyPreferencesStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (prefs) => _PrivacySettingsContent(prefs: prefs),
      ),
    );
  }
}

class _PrivacySettingsContent extends ConsumerWidget {
  const _PrivacySettingsContent({required this.prefs});

  final PrivacyPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(privacyPreferencesNotifierProvider.notifier);

    return ListView(
      children: [
        const SizedBox(height: AppSpacing.space4),

        // Profile Visibility Section
        _SectionHeader(title: 'Profile Visibility'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _VisibilitySelector(
                currentVisibility: prefs.profileVisibility,
                onChanged: (visibility) {
                  notifier.setProfileVisibility(visibility);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Profile Information Section
        _SectionHeader(title: 'Profile Information'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _SettingsToggle(
                icon: Icons.location_on_outlined,
                title: 'Show Location',
                subtitle: 'Display your location on your profile',
                value: prefs.showLocation,
                onChanged: (value) => notifier.setShowLocation(value),
              ),
              _SettingsToggle(
                icon: Icons.phone_outlined,
                title: 'Show Phone Number',
                subtitle: 'Allow others to see your phone number',
                value: prefs.showPhoneNumber,
                onChanged: (value) => notifier.setShowPhoneNumber(value),
              ),
              _SettingsToggle(
                icon: Icons.inventory_2_outlined,
                title: 'Show Listings Count',
                subtitle: 'Display number of items you have listed',
                value: prefs.showListingsCount,
                onChanged: (value) => notifier.setShowListingsCount(value),
              ),
              _SettingsToggle(
                icon: Icons.receipt_long_outlined,
                title: 'Show Purchase History',
                subtitle: 'Let others see items you have purchased',
                value: prefs.showPurchaseHistory,
                onChanged: (value) => notifier.setShowPurchaseHistory(value),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Activity & Messaging Section
        _SectionHeader(title: 'Activity & Messaging'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _SettingsToggle(
                icon: Icons.circle,
                title: 'Show Online Status',
                subtitle: 'Let others know when you are active',
                value: prefs.showOnlineStatus,
                onChanged: (value) => notifier.setShowOnlineStatus(value),
              ),
              _MessagePermissionSelector(
                currentPermission: prefs.messagePermission,
                onChanged: (permission) {
                  notifier.setMessagePermission(permission);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Discoverability Section
        _SectionHeader(title: 'Discoverability'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _SettingsToggle(
                icon: Icons.search,
                title: 'Appear in Search',
                subtitle: 'Allow your profile to appear in search results',
                value: prefs.appearInSearch,
                onChanged: (value) => notifier.setAppearInSearch(value),
              ),
              _SettingsToggle(
                icon: Icons.share_outlined,
                title: 'Allow Profile Sharing',
                subtitle: 'Let others share your profile via link',
                value: prefs.allowProfileSharing,
                onChanged: (value) => notifier.setAllowProfileSharing(value),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Your Data Section
        _SectionHeader(title: 'Your Data'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.download_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
                title: const Text(
                  'Export Your Data',
                  style: AppTypography.bodyLarge,
                ),
                subtitle: Text(
                  'Download a copy of your personal data',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                ),
                onTap: () => context.push(AppRoutes.dataExport),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Info note
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
                Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    'Your privacy settings affect how other users see and interact with your profile. Sellers should keep profiles public for better discoverability.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.space10),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space2,
        AppSpacing.space4,
        AppSpacing.space2,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(title, style: AppTypography.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  const _VisibilitySelector({
    required this.currentVisibility,
    required this.onChanged,
  });

  final ProfileVisibility currentVisibility;
  final ValueChanged<ProfileVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ProfileVisibility.values.map((visibility) {
        final isSelected = visibility == currentVisibility;
        return ListTile(
          leading: Icon(
            _getIconForVisibility(visibility),
            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          title: Text(
            visibility.displayName,
            style: AppTypography.bodyLarge.copyWith(
              color: isSelected ? AppColors.primary : AppColors.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            visibility.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppColors.primary)
              : const Icon(Icons.circle_outlined, color: AppColors.outline),
          onTap: () => onChanged(visibility),
        );
      }).toList(),
    );
  }

  IconData _getIconForVisibility(ProfileVisibility visibility) {
    switch (visibility) {
      case ProfileVisibility.public:
        return Icons.public;
      case ProfileVisibility.buyersOnly:
        return Icons.people_outline;
      case ProfileVisibility.private:
        return Icons.lock_outline;
    }
  }
}

class _MessagePermissionSelector extends StatelessWidget {
  const _MessagePermissionSelector({
    required this.currentPermission,
    required this.onChanged,
  });

  final MessagePermission currentPermission;
  final ValueChanged<MessagePermission> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.chat_bubble_outline,
        color: AppColors.onSurfaceVariant,
      ),
      title: const Text('Who Can Message You', style: AppTypography.bodyLarge),
      subtitle: Text(
        currentPermission.displayName,
        style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: () => _showPermissionPicker(context),
    );
  }

  void _showPermissionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(
                'Who Can Message You',
                style: AppTypography.titleMedium,
              ),
            ),
            ...MessagePermission.values.map((permission) {
              final isSelected = permission == currentPermission;
              return ListTile(
                leading: Icon(
                  _getIconForPermission(permission),
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                title: Text(
                  permission.displayName,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  permission.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  onChanged(permission);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: AppSpacing.space4),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPermission(MessagePermission permission) {
    switch (permission) {
      case MessagePermission.everyone:
        return Icons.public;
      case MessagePermission.verifiedOnly:
        return Icons.verified_user_outlined;
      case MessagePermission.noOne:
        return Icons.block;
    }
  }
}
