import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/location_provider.dart';

/// Cached package info provider
final _packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

/// App settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final packageInfo = ref.watch(_packageInfoProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Account section
          _SectionHeader(title: 'Account'),
          Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => context.push('/profile/edit'),
                ),
                _SettingsTile(
                  icon: Icons.block_outlined,
                  title: 'Blocked Users',
                  onTap: () => context.push(AppRoutes.blockedUsers),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Privacy',
                  onTap: () => context.push(AppRoutes.privacySettings),
                ),
                _SettingsTile(
                  icon: Icons.security_outlined,
                  title: 'Security',
                  onTap: () => context.push(AppRoutes.securitySettings),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Notifications section
          _SectionHeader(title: 'Notifications'),
          Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notification Settings',
                  enabled: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Preferences section
          _SectionHeader(title: 'Preferences'),
          Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  trailing: Text(
                    'English',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  enabled: false,
                ),
                _LocationTile(),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Support section
          _SectionHeader(title: 'Support'),
          Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () => context.push(AppRoutes.help),
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Safety Tips',
                  onTap: () => context.push(AppRoutes.safetyTips),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => context.push(AppRoutes.termsOfService),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // About section
          _SectionHeader(title: 'About'),
          Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  trailing: packageInfo.when(
                    data: (info) => Text(
                      '${info.version} (${info.buildNumber})',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => Text(
                      'Unknown',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  showChevron: false,
                  onTap: null,
                ),
                _SettingsTile(
                  icon: Icons.star_outline,
                  title: 'Rate the App',
                  enabled: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Danger zone
          Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  isDestructive: true,
                  onTap: () => _showSignOutDialog(context, ref),
                ),
                _SettingsTile(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  isDestructive: true,
                  onTap: () => context.push(AppRoutes.accountDeletion),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space10),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showChevron;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOpacity = enabled ? 1.0 : 0.45;

    return Opacity(
      opacity: effectiveOpacity,
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive
              ? colorScheme.error
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            color: isDestructive ? colorScheme.error : colorScheme.onSurface,
          ),
        ),
        trailing: !enabled
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Coming Soon',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : trailing ??
                (showChevron && onTap != null
                    ? Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null),
        onTap: enabled
            ? onTap
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature coming soon'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
      ),
    );
  }
}

class _LocationTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationPreferencesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        Icons.location_on_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
      title: Text('Default Location', style: AppTypography.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locationState.selectedLocation.displayName,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: () => context.push(AppRoutes.defaultLocation),
    );
  }
}
