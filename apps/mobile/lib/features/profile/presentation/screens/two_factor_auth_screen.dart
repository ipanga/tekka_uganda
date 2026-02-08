import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/theme.dart';
import '../../application/two_factor_auth_provider.dart';

/// Screen for setting up and managing two-factor authentication
class TwoFactorAuthScreen extends ConsumerStatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  ConsumerState<TwoFactorAuthScreen> createState() =>
      _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends ConsumerState<TwoFactorAuthScreen> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(twoFactorAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (status.state == TwoFactorState.methodSelection ||
                status.state == TwoFactorState.setupSms ||
                status.state == TwoFactorState.setupAuthenticator ||
                status.state == TwoFactorState.verifyingCode) {
              ref.read(twoFactorAuthProvider.notifier).cancelSetup();
            }
            context.pop();
          },
        ),
      ),
      body: _buildBody(status),
    );
  }

  Widget _buildBody(TwoFactorStatus status) {
    if (status.isLoading && status.state == TwoFactorState.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (status.state) {
      case TwoFactorState.initial:
      case TwoFactorState.disabled:
        return _buildDisabledView(status);
      case TwoFactorState.enabled:
        return _buildEnabledView(status);
      case TwoFactorState.methodSelection:
        return _buildMethodSelection();
      case TwoFactorState.setupSms:
        return _buildSmsSetup(status);
      case TwoFactorState.setupAuthenticator:
        return _buildAuthenticatorSetup(status);
      case TwoFactorState.verifyingCode:
        return _buildCodeVerification(status);
      case TwoFactorState.loading:
        return const Center(child: CircularProgressIndicator());
      case TwoFactorState.error:
        return _buildErrorView(status);
    }
  }

  Widget _buildDisabledView(TwoFactorStatus status) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.space4),

        // Info card
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: AppSpacing.cardRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    'Add Extra Security',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Two-factor authentication adds an extra layer of security to your account. You\'ll need to enter a verification code in addition to your password when signing in.',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // Benefits
        Text('Benefits', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.space3),

        _BenefitItem(
          icon: Icons.lock_outline,
          title: 'Protect Your Account',
          description:
              'Even if someone gets your password, they can\'t access your account.',
        ),
        const SizedBox(height: AppSpacing.space3),
        _BenefitItem(
          icon: Icons.verified_user_outlined,
          title: 'Secure Transactions',
          description:
              'Add protection when making sensitive changes to your account.',
        ),
        const SizedBox(height: AppSpacing.space3),
        _BenefitItem(
          icon: Icons.phone_android_outlined,
          title: 'Your Choice',
          description:
              'Use SMS or an authenticator app - whichever works best for you.',
        ),

        const SizedBox(height: AppSpacing.space8),

        // Enable button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              ref.read(twoFactorAuthProvider.notifier).startSetup();
            },
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Enable Two-Factor Authentication'),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildEnabledView(TwoFactorStatus status) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.space4),

        // Status card
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.success),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2FA is Enabled',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Using ${status.activeMethod?.displayName ?? 'Unknown'}',
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

        // Options
        Text('Options', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.space3),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.key_outlined),
                title: const Text('View Backup Codes'),
                subtitle: const Text(
                  'Use these if you lose access to your device',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showBackupCodes(status),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.refresh_outlined),
                title: const Text('Regenerate Backup Codes'),
                subtitle: const Text(
                  'Generate new codes (old ones will stop working)',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _regenerateBackupCodes(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.swap_horiz_outlined),
                title: const Text('Change Method'),
                subtitle: Text(
                  'Currently: ${status.activeMethod?.displayName ?? 'Unknown'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(twoFactorAuthProvider.notifier).startSetup();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // Disable button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDisableConfirmation(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            ),
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Disable Two-Factor Authentication'),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildMethodSelection() {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.space4),

        Text('Choose a Method', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Select how you\'d like to receive verification codes',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // SMS option
        _MethodCard(
          icon: Icons.sms_outlined,
          title: TwoFactorMethod.sms.displayName,
          description: TwoFactorMethod.sms.description,
          onTap: () {
            ref
                .read(twoFactorAuthProvider.notifier)
                .selectMethod(TwoFactorMethod.sms);
          },
        ),

        const SizedBox(height: AppSpacing.space4),

        // Authenticator app option
        _MethodCard(
          icon: Icons.phonelink_lock_outlined,
          title: TwoFactorMethod.authenticatorApp.displayName,
          description: TwoFactorMethod.authenticatorApp.description,
          recommended: true,
          onTap: () {
            ref
                .read(twoFactorAuthProvider.notifier)
                .selectMethod(TwoFactorMethod.authenticatorApp);
          },
        ),

        const SizedBox(height: AppSpacing.space6),

        // Cancel button
        TextButton(
          onPressed: () {
            ref.read(twoFactorAuthProvider.notifier).cancelSetup();
            context.pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildSmsSetup(TwoFactorStatus status) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.space4),

        Text('SMS Verification', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'We\'ll send verification codes to your phone number',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // Phone number display
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone Number',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      status.phoneNumber ?? 'Not available',
                      style: AppTypography.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // Send code button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: status.isLoading
                ? null
                : () async {
                    await ref
                        .read(twoFactorAuthProvider.notifier)
                        .sendSmsCode();
                  },
            child: status.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Verification Code'),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        TextButton(
          onPressed: () {
            ref.read(twoFactorAuthProvider.notifier).cancelSetup();
          },
          child: const Text('Choose Different Method'),
        ),
      ],
    );
  }

  Widget _buildAuthenticatorSetup(TwoFactorStatus status) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.space4),

        Text('Authenticator App Setup', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Scan this QR code with your authenticator app',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // QR code for authenticator app
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: status.qrCodeUrl != null
                    ? QrImageView(
                        data: status.qrCodeUrl!,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: AppColors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        padding: const EdgeInsets.all(12),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.space2),
                            Text(
                              'Generating QR Code...',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Can\'t scan? Enter this key manually:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.secretKey ?? '',
                      style: AppTypography.bodyMedium.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: status.secretKey ?? ''),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Key copied to clipboard'),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // Continue button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ref
                  .read(twoFactorAuthProvider.notifier)
                  .proceedToCodeVerification();
            },
            child: const Text('I\'ve Scanned the QR Code'),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        TextButton(
          onPressed: () {
            ref.read(twoFactorAuthProvider.notifier).cancelSetup();
          },
          child: const Text('Choose Different Method'),
        ),
      ],
    );
  }

  Widget _buildCodeVerification(TwoFactorStatus status) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.space4),

        Text('Enter Verification Code', style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.space2),
        Text(
          status.activeMethod == TwoFactorMethod.sms
              ? 'Enter the 6-digit code we sent to your phone'
              : 'Enter the 6-digit code from your authenticator app',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // Code input
        TextField(
          controller: _codeController,
          focusNode: _codeFocusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: AppTypography.headlineMedium.copyWith(letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            if (value.length == 6) {
              _verifyCode();
            }
          },
        ),

        if (status.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space3),
          Text(
            status.errorMessage!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: AppSpacing.space6),

        // Verify button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: status.isLoading ? null : _verifyCode,
            child: status.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
          ),
        ),

        if (status.activeMethod == TwoFactorMethod.sms) ...[
          const SizedBox(height: AppSpacing.space4),
          TextButton(
            onPressed: status.isLoading
                ? null
                : () {
                    ref.read(twoFactorAuthProvider.notifier).sendSmsCode();
                  },
            child: const Text('Resend Code'),
          ),
        ],

        const SizedBox(height: AppSpacing.space4),

        TextButton(
          onPressed: () {
            ref.read(twoFactorAuthProvider.notifier).cancelSetup();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildErrorView(TwoFactorStatus status) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text('Something went wrong', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.space2),
            Text(
              status.errorMessage ?? 'An error occurred',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton(
              onPressed: () {
                ref.read(twoFactorAuthProvider.notifier).cancelSetup();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text;
    if (code.length != 6) return;

    final success = await ref
        .read(twoFactorAuthProvider.notifier)
        .verifyCode(code);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-factor authentication enabled!'),
          backgroundColor: AppColors.success,
        ),
      );
      _codeController.clear();
    }
  }

  void _showBackupCodes(TwoFactorStatus status) {
    final backupCodes = status.backupCodes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save these codes in a safe place. Each code can only be used once.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            if (backupCodes != null && backupCodes.isNotEmpty)
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: backupCodes
                      .map(
                        (code) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            code,
                            style: AppTypography.bodyMedium.copyWith(
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
            else
              Text(
                'No backup codes available. Generate new ones.',
                style: AppTypography.bodyMedium,
              ),
          ],
        ),
        actions: [
          if (backupCodes != null && backupCodes.isNotEmpty)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: backupCodes.join('\n')));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Codes copied to clipboard')),
                );
              },
              child: const Text('Copy All'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateBackupCodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Backup Codes?'),
        content: const Text(
          'This will invalidate all your existing backup codes. Make sure to save the new codes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newCodes = await ref
          .read(twoFactorAuthProvider.notifier)
          .regenerateBackupCodes();

      if (newCodes != null && mounted) {
        _showBackupCodes(ref.read(twoFactorAuthProvider));
      }
    }
  }

  void _showDisableConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable 2FA?'),
        content: const Text(
          'Your account will be less secure without two-factor authentication. Are you sure you want to disable it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(twoFactorAuthProvider.notifier)
                  .disable2FA();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Two-factor authentication disabled'),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleSmall),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool recommended;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    this.recommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: recommended ? AppColors.primary : AppColors.outline,
            width: recommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppTypography.titleSmall),
                      if (recommended) ...[
                        const SizedBox(width: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommended',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
