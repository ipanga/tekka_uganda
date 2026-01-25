import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/app_lock_provider.dart';
import '../../application/biometric_auth_provider.dart';
import '../../application/pin_provider.dart';

/// Screen for configuring app lock settings
class AppLockSettingsScreen extends ConsumerWidget {
  const AppLockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLockStatus = ref.watch(appLockProvider);
    final pinStatus = ref.watch(pinProvider);
    final biometricStatus = ref.watch(biometricAuthProvider);

    // Listen for errors
    ref.listen<AppLockStatus>(appLockProvider, (prev, next) {
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(appLockProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Lock'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Current status
          _buildStatusHeader(appLockStatus),

          const SizedBox(height: AppSpacing.space4),

          // Lock mode selection
          _SectionHeader(title: 'Lock Mode'),
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                _LockModeOption(
                  mode: AppLockMode.off,
                  currentMode: appLockStatus.mode,
                  isEnabled: true,
                  onTap: () => _setMode(ref, AppLockMode.off),
                ),
                _LockModeOption(
                  mode: AppLockMode.pinOnly,
                  currentMode: appLockStatus.mode,
                  isEnabled: pinStatus.hasPinSet,
                  disabledReason: 'Set up a PIN first',
                  onTap: () => _setMode(ref, AppLockMode.pinOnly),
                  onSetup: () => context.push(AppRoutes.changePin),
                ),
                _LockModeOption(
                  mode: AppLockMode.biometricOnly,
                  currentMode: appLockStatus.mode,
                  isEnabled: biometricStatus.isAvailable && biometricStatus.isEnrolled,
                  disabledReason: biometricStatus.isAvailable
                      ? 'Set up biometrics in device settings'
                      : 'Not available on this device',
                  onTap: () => _setMode(ref, AppLockMode.biometricOnly),
                ),
                _LockModeOption(
                  mode: AppLockMode.biometricOrPin,
                  currentMode: appLockStatus.mode,
                  isEnabled: pinStatus.hasPinSet &&
                      biometricStatus.isAvailable &&
                      biometricStatus.isEnrolled,
                  disabledReason: !pinStatus.hasPinSet
                      ? 'Set up a PIN first'
                      : 'Set up biometrics in device settings',
                  onTap: () => _setMode(ref, AppLockMode.biometricOrPin),
                  onSetup: !pinStatus.hasPinSet
                      ? () => context.push(AppRoutes.changePin)
                      : null,
                ),
              ],
            ),
          ),

          if (appLockStatus.isEnabled) ...[
            const SizedBox(height: AppSpacing.space4),

            // Timeout settings
            _SectionHeader(title: 'Auto-Lock'),
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  _TimeoutOption(
                    minutes: 0,
                    label: 'Immediately',
                    currentTimeout: appLockStatus.lockTimeoutMinutes,
                    onTap: () => _setTimeout(ref, 0),
                  ),
                  _TimeoutOption(
                    minutes: 1,
                    label: 'After 1 minute',
                    currentTimeout: appLockStatus.lockTimeoutMinutes,
                    onTap: () => _setTimeout(ref, 1),
                  ),
                  _TimeoutOption(
                    minutes: 5,
                    label: 'After 5 minutes',
                    currentTimeout: appLockStatus.lockTimeoutMinutes,
                    onTap: () => _setTimeout(ref, 5),
                  ),
                  _TimeoutOption(
                    minutes: 15,
                    label: 'After 15 minutes',
                    currentTimeout: appLockStatus.lockTimeoutMinutes,
                    onTap: () => _setTimeout(ref, 15),
                  ),
                  _TimeoutOption(
                    minutes: 30,
                    label: 'After 30 minutes',
                    currentTimeout: appLockStatus.lockTimeoutMinutes,
                    onTap: () => _setTimeout(ref, 30),
                  ),
                ],
              ),
            ),
          ],

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
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      'App Lock adds an extra layer of security. When enabled, you\'ll need to authenticate to access Tekka after the app has been in the background.',
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
      ),
    );
  }

  Widget _buildStatusHeader(AppLockStatus status) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: status.isEnabled
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: status.isEnabled ? AppColors.success : AppColors.outline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: status.isEnabled
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                status.isEnabled ? Icons.lock : Icons.lock_open,
                color: status.isEnabled ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.isEnabled ? 'App Lock Enabled' : 'App Lock Disabled',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.isEnabled
                        ? status.mode.description
                        : 'Your app is not protected',
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

  void _setMode(WidgetRef ref, AppLockMode mode) {
    ref.read(appLockProvider.notifier).setMode(mode);
  }

  void _setTimeout(WidgetRef ref, int minutes) {
    ref.read(appLockProvider.notifier).setTimeout(minutes);
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

class _LockModeOption extends StatelessWidget {
  const _LockModeOption({
    required this.mode,
    required this.currentMode,
    required this.isEnabled,
    required this.onTap,
    this.disabledReason,
    this.onSetup,
  });

  final AppLockMode mode;
  final AppLockMode currentMode;
  final bool isEnabled;
  final VoidCallback onTap;
  final String? disabledReason;
  final VoidCallback? onSetup;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;

    return ListTile(
      leading: Icon(
        _getModeIcon(mode),
        color: isEnabled
            ? (isSelected ? AppColors.primary : AppColors.onSurfaceVariant)
            : AppColors.gray400,
      ),
      title: Text(
        mode.displayName,
        style: AppTypography.bodyLarge.copyWith(
          color: isEnabled ? AppColors.onSurface : AppColors.gray400,
        ),
      ),
      subtitle: !isEnabled && disabledReason != null
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    disabledReason!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                ),
                if (onSetup != null)
                  TextButton(
                    onPressed: onSetup,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Set up'),
                  ),
              ],
            )
          : Text(
              mode.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
      trailing: isEnabled
          ? Radio<AppLockMode>(
              value: mode,
              groupValue: currentMode,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            )
          : null,
      onTap: isEnabled ? onTap : null,
    );
  }

  IconData _getModeIcon(AppLockMode mode) {
    switch (mode) {
      case AppLockMode.off:
        return Icons.lock_open;
      case AppLockMode.pinOnly:
        return Icons.pin;
      case AppLockMode.biometricOnly:
        return Icons.fingerprint;
      case AppLockMode.biometricOrPin:
        return Icons.security;
    }
  }
}

class _TimeoutOption extends StatelessWidget {
  const _TimeoutOption({
    required this.minutes,
    required this.label,
    required this.currentTimeout,
    required this.onTap,
  });

  final int minutes;
  final String label;
  final int currentTimeout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = minutes == currentTimeout;

    return ListTile(
      title: Text(
        label,
        style: AppTypography.bodyLarge,
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
