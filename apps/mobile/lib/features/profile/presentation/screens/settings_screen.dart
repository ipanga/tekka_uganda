import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/rate_app_provider.dart';
import '../../application/language_provider.dart';
import '../../application/location_provider.dart';
import '../../application/theme_provider.dart';
import '../widgets/rate_app_dialog.dart';

/// App settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  onTap: () => context.push(AppRoutes.notificationSettings),
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
              children: [_ThemeTile(), _LanguageTile(), _LocationTile()],
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
                  trailing: Text(
                    '1.0.0',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  showChevron: false,
                  onTap: null,
                ),
                _SettingsTile(
                  icon: Icons.star_outline,
                  title: 'Rate the App',
                  onTap: () => _showRateAppDialog(context, ref),
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
                  onTap: () => _showDeleteAccountDialog(context),
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

  void _showDeleteAccountDialog(BuildContext context) {
    context.push(AppRoutes.accountDeletion);
  }

  void _showRateAppDialog(BuildContext context, WidgetRef ref) {
    final rateAppState = ref.read(rateAppProvider);

    // If user has already rated, show a thank you message
    if (rateAppState.hasRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for rating Tekka!'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    // Show the rate app bottom sheet
    RateAppBottomSheet.show(context);
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
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? colorScheme.error : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: isDestructive ? colorScheme.error : colorScheme.onSurface,
        ),
      ),
      trailing:
          trailing ??
          (showChevron && onTap != null
              ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
              : null),
      onTap: onTap,
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        themeState.selectedTheme.icon,
        color: colorScheme.onSurfaceVariant,
      ),
      title: Text('Theme', style: AppTypography.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            themeState.selectedTheme.displayName,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: () => _showThemeBottomSheet(context, ref),
    );
  }

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider).selectedTheme;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space2,
              ),
              child: Text('Choose Theme', style: AppTypography.titleLarge),
            ),
            ...AppThemeMode.values.map(
              (mode) => ListTile(
                leading: Icon(mode.icon),
                title: Text(mode.displayName, style: AppTypography.bodyLarge),
                trailing: currentTheme == mode
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(mode);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(Icons.language, color: colorScheme.onSurfaceVariant),
      title: Text('Language', style: AppTypography.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageState.selectedLanguage.displayName,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: () => context.push(AppRoutes.language),
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
