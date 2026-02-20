import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/app_lock_provider.dart';
import '../../application/biometric_auth_provider.dart';
import '../../application/security_provider.dart';
import '../../application/two_factor_auth_provider.dart';
import '../../application/pin_provider.dart';
import '../../domain/entities/security_preferences.dart';

/// Security settings screen
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(securityPreferencesStreamProvider);
    final verificationAsync = ref.watch(verificationStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Security')),
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
                    ref.invalidate(securityPreferencesStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (prefs) => _SecuritySettingsContent(
          prefs: prefs,
          verificationAsync: verificationAsync,
        ),
      ),
    );
  }
}

class _SecuritySettingsContent extends ConsumerWidget {
  const _SecuritySettingsContent({
    required this.prefs,
    required this.verificationAsync,
  });

  final SecurityPreferences prefs;
  final AsyncValue<VerificationStatus> verificationAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const SizedBox(height: AppSpacing.space4),

        // Verification Status Section
        _SectionHeader(title: 'Verification Status'),
        Container(
          color: AppColors.surface,
          child: verificationAsync.when(
            loading: () => const Padding(
              padding: AppSpacing.screenPadding,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: AppSpacing.screenPadding,
              child: Text('Failed to load verification status'),
            ),
            data: (status) => _VerificationStatusCard(status: status),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Authentication Section
        _SectionHeader(title: 'Authentication'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _AppLockTile(),
              _BiometricTile(),
              _TwoFactorTile(prefs: prefs),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Security Alerts Section
        _SectionHeader(title: 'Security Alerts'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _SettingsToggle(
                icon: Icons.notifications_active_outlined,
                title: 'Login Alerts',
                subtitle: 'Get notified of new sign-ins',
                value: prefs.loginAlerts,
                onChanged: (value) => ref.read(securityPreferencesNotifierProvider.notifier).setLoginAlerts(value),
              ),
              _SettingsToggle(
                icon: Icons.payment_outlined,
                title: 'Transaction Confirmation',
                subtitle:
                    'Require confirmation for offers above ${_formatCurrency(prefs.transactionThreshold)}',
                value: prefs.requireTransactionConfirmation,
                onChanged: (value) =>
                    ref.read(securityPreferencesNotifierProvider.notifier).setTransactionConfirmation(value),
              ),
              if (prefs.requireTransactionConfirmation)
                _ThresholdSelector(
                  currentThreshold: prefs.transactionThreshold,
                  onChanged: (value) => ref.read(securityPreferencesNotifierProvider.notifier).setTransactionThreshold(value),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Active Sessions Section
        _SectionHeader(title: 'Active Sessions'),
        Container(color: AppColors.surface, child: _SessionsList()),

        const SizedBox(height: AppSpacing.space4),

        // Account Actions Section
        _SectionHeader(title: 'Account Actions'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.logout,
                title: 'Sign Out All Devices',
                subtitle: 'Sign out from all other devices',
                onTap: () => _showSignOutAllDialog(context, ref),
              ),
              _PinTile(),
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
                Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    'Keep your account secure by enabling biometric login and login alerts. Never share your verification codes with anyone.',
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

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return 'UGX ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'UGX ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'UGX $amount';
  }

  void _showSignOutAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out All Devices?'),
        content: const Text(
          'This will sign you out from all devices, including this one. You will need to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(signOutAllDevicesProvider)();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out All'),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _VerificationStatusCard extends StatelessWidget {
  const _VerificationStatusCard({required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          // Verification badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: _getBadgeColor(status.verificationLevel),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getBadgeIcon(status.verificationLevel),
                  size: 18,
                  color: AppColors.white,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  status.verificationBadge,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Verification items
          _VerificationItem(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            isVerified: status.phoneVerified,
            verifiedAt: status.phoneVerifiedAt,
          ),
          const Divider(height: 1),
          _VerificationItem(
            icon: Icons.email_outlined,
            title: 'Email Address',
            isVerified: status.emailVerified,
            verifiedAt: status.emailVerifiedAt,
            onVerify: () => context.push(AppRoutes.emailVerification),
          ),
          const Divider(height: 1),
          _VerificationItem(
            icon: Icons.badge_outlined,
            title: 'Identity',
            isVerified: status.identityVerified,
            verifiedAt: status.identityVerifiedAt,
            onVerify: () => context.push(AppRoutes.identityVerification),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(int level) {
    switch (level) {
      case 3:
        return AppColors.success;
      case 2:
        return AppColors.primary;
      case 1:
        return AppColors.gold;
      default:
        return AppColors.gray400;
    }
  }

  IconData _getBadgeIcon(int level) {
    switch (level) {
      case 3:
        return Icons.verified;
      case 2:
        return Icons.verified_user;
      case 1:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }
}

class _VerificationItem extends StatelessWidget {
  const _VerificationItem({
    required this.icon,
    required this.title,
    required this.isVerified,
    this.verifiedAt,
    this.onVerify,
  });

  final IconData icon;
  final String title;
  final bool isVerified;
  final DateTime? verifiedAt;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                if (isVerified && verifiedAt != null)
                  Text(
                    'Verified ${_formatDate(verifiedAt!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
          if (isVerified)
            const Icon(Icons.check_circle, color: AppColors.success, size: 20)
          else if (onVerify != null)
            TextButton(onPressed: onVerify, child: const Text('Verify'))
          else
            Icon(
              Icons.circle_outlined,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _ThresholdSelector extends StatelessWidget {
  const _ThresholdSelector({
    required this.currentThreshold,
    required this.onChanged,
  });

  final int currentThreshold;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final thresholds = [100000, 250000, 500000, 1000000, 2000000];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        AppSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmation threshold',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: thresholds.map((threshold) {
              final isSelected = threshold == currentThreshold;
              return ChoiceChip(
                label: Text(_formatCurrency(threshold)),
                selected: isSelected,
                onSelected: (_) => onChanged(threshold),
                selectedColor: AppColors.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return 'UGX ${(amount / 1000000).toStringAsFixed(0)}M';
    } else if (amount >= 1000) {
      return 'UGX ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'UGX $amount';
  }
}

class _SessionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(loginSessionsProvider);

    return sessionsAsync.when(
      loading: () => const Padding(
        padding: AppSpacing.screenPadding,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: AppSpacing.screenPadding,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Could not load sessions',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Padding(
            padding: AppSpacing.screenPadding,
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.devices,
                    color: AppColors.onSurfaceVariant,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'This is your only active session',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: sessions.map((session) {
            return _SessionTile(session: session);
          }).toList(),
        );
      },
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final LoginSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        _getDeviceIcon(session.deviceType),
        color: session.isCurrent
            ? AppColors.primary
            : AppColors.onSurfaceVariant,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(session.deviceName, style: AppTypography.bodyMedium),
          ),
          if (session.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Current',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${session.location} • ${_formatDate(session.loginTime)}',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: session.isCurrent
          ? null
          : IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => _showTerminateDialog(context, ref),
            ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet_android;
      case 'desktop':
        return Icons.computer;
      case 'web':
        return Icons.language;
      default:
        return Icons.devices;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  void _showTerminateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: Text(
          'This will sign out "${session.deviceName}" from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(terminateSessionProvider(session.id))();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Session ended')));
              }
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}

class _TwoFactorTile extends ConsumerWidget {
  const _TwoFactorTile({required this.prefs});

  final SecurityPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final twoFactorStatus = ref.watch(twoFactorAuthProvider);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: twoFactorStatus.isEnabled
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.security,
          color: twoFactorStatus.isEnabled
              ? AppColors.success
              : AppColors.primary,
        ),
      ),
      title: const Text('Two-Factor Authentication'),
      subtitle: Text(
        twoFactorStatus.isEnabled
            ? 'Enabled via ${twoFactorStatus.activeMethod?.displayName ?? 'Unknown'}'
            : 'Add extra security to your account',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (twoFactorStatus.isEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ON',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ],
      ),
      onTap: () => context.push(AppRoutes.twoFactorAuth),
    );
  }
}

class _PinTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinStatus = ref.watch(pinProvider);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: pinStatus.hasPinSet
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.password_outlined,
          color: pinStatus.hasPinSet ? AppColors.success : AppColors.primary,
        ),
      ),
      title: Text(
        pinStatus.hasPinSet ? 'Change PIN' : 'Set Up PIN',
        style: AppTypography.bodyLarge,
      ),
      subtitle: Text(
        pinStatus.hasPinSet
            ? 'Update your account PIN'
            : 'Add an extra layer of security',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pinStatus.hasPinSet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ON',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ],
      ),
      onTap: () => context.push(AppRoutes.changePin),
    );
  }
}

class _BiometricTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricStatus = ref.watch(biometricAuthProvider);

    // Listen for errors
    ref.listen<BiometricStatus>(biometricAuthProvider, (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(biometricAuthProvider.notifier).clearError();
      }
    });

    // Determine icon and subtitle based on availability
    IconData icon;
    String subtitle;

    if (!biometricStatus.isAvailable) {
      icon = Icons.fingerprint;
      subtitle = 'Not available on this device';
    } else if (!biometricStatus.isEnrolled) {
      icon = Icons.fingerprint;
      subtitle = 'Set up biometrics in device settings';
    } else {
      icon = biometricStatus.primaryType == AppBiometricType.faceId
          ? Icons.face
          : Icons.fingerprint;
      subtitle = biometricStatus.isEnabled
          ? 'Using ${biometricStatus.biometricName} to sign in'
          : 'Use ${biometricStatus.biometricName} to sign in';
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: biometricStatus.isEnabled
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: biometricStatus.isLoading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                icon,
                color: biometricStatus.isEnabled
                    ? AppColors.success
                    : biometricStatus.isAvailable
                    ? AppColors.primary
                    : AppColors.gray400,
              ),
      ),
      title: Text(
        'Biometric Login',
        style: AppTypography.bodyLarge.copyWith(
          color: biometricStatus.isAvailable
              ? AppColors.onSurface
              : AppColors.gray400,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: biometricStatus.isEnabled,
        onChanged:
            biometricStatus.isAvailable &&
                biometricStatus.isEnrolled &&
                !biometricStatus.isLoading
            ? (value) async {
                if (value) {
                  await ref
                      .read(biometricAuthProvider.notifier)
                      .enableBiometric();
                } else {
                  await ref
                      .read(biometricAuthProvider.notifier)
                      .disableBiometric();
                }
              }
            : null,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

class _AppLockTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLockStatus = ref.watch(appLockProvider);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: appLockStatus.isEnabled
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          appLockStatus.isEnabled ? Icons.lock : Icons.lock_open,
          color: appLockStatus.isEnabled
              ? AppColors.success
              : AppColors.primary,
        ),
      ),
      title: Text('App Lock', style: AppTypography.bodyLarge),
      subtitle: Text(
        appLockStatus.isEnabled
            ? appLockStatus.mode.displayName
            : 'Protect app with PIN or biometric',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (appLockStatus.isEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ON',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ],
      ),
      onTap: () => context.push(AppRoutes.appLockSettings),
    );
  }
}
