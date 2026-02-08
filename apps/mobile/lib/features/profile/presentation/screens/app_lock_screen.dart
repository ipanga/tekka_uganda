import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../application/app_lock_provider.dart';
import '../../application/biometric_auth_provider.dart';

/// Screen shown when app is locked
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, this.onUnlocked});

  final VoidCallback? onUnlocked;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  bool _showPinInput = false;

  @override
  void initState() {
    super.initState();
    // Try biometric auth automatically on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricUnlock() async {
    final appLockStatus = ref.read(appLockProvider);
    if (appLockStatus.canUseBiometric) {
      final success = await ref
          .read(appLockProvider.notifier)
          .unlockWithBiometric();
      if (success) {
        widget.onUnlocked?.call();
      } else if (appLockStatus.canUsePin) {
        // Fall back to PIN if biometric fails
        setState(() {
          _showPinInput = true;
        });
      }
    } else if (appLockStatus.canUsePin) {
      setState(() {
        _showPinInput = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLockStatus = ref.watch(appLockProvider);
    final biometricStatus = ref.watch(biometricAuthProvider);

    // Listen for unlock success
    ref.listen<AppLockStatus>(appLockProvider, (prev, next) {
      if (prev?.isLocked == true && !next.isLocked) {
        widget.onUnlocked?.call();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const Spacer(),

              // App logo and title
              _buildHeader(),

              const SizedBox(height: AppSpacing.space10),

              // PIN input or biometric prompt
              if (_showPinInput && appLockStatus.canUsePin)
                _buildPinInput(appLockStatus)
              else
                _buildBiometricPrompt(appLockStatus, biometricStatus),

              const Spacer(),

              // Footer with options
              _buildFooter(appLockStatus),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo placeholder
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.lock_outline, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Tekka',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Unlock to continue',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPinInput(AppLockStatus status) {
    return Column(
      children: [
        // PIN dots display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < _pinController.text.length;
            final isActive = index == _pinController.text.length;

            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.outline,
                  width: isActive ? 2 : 1,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Hidden text field
        SizedBox(
          width: 1,
          height: 1,
          child: TextField(
            controller: _pinController,
            focusNode: _pinFocusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {});
              if (value.length >= 4) {
                _handlePinSubmit();
              }
            },
          ),
        ),

        // Tap to focus hint
        GestureDetector(
          onTap: () => _pinFocusNode.requestFocus(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            child: Text(
              'Tap to enter PIN',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),

        if (status.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  status.errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.space6),

        // Unlock button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _pinController.text.length >= 4 && !status.isLoading
                ? _handlePinSubmit
                : null,
            child: status.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Unlock'),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricPrompt(
    AppLockStatus appLockStatus,
    BiometricStatus biometricStatus,
  ) {
    final icon = biometricStatus.primaryType == AppBiometricType.faceId
        ? Icons.face
        : Icons.fingerprint;

    return Column(
      children: [
        // Biometric icon
        GestureDetector(
          onTap: _tryBiometricUnlock,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: appLockStatus.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(icon, size: 40, color: AppColors.primary),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        Text(
          'Tap to unlock with ${biometricStatus.biometricName}',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),

        if (appLockStatus.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              appLockStatus.errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.space6),

        // Try again button
        OutlinedButton(
          onPressed: appLockStatus.isLoading ? null : _tryBiometricUnlock,
          child: Text('Try ${biometricStatus.biometricName}'),
        ),
      ],
    );
  }

  Widget _buildFooter(AppLockStatus status) {
    return Column(
      children: [
        // Switch between PIN and biometric
        if (status.canUsePin && status.canUseBiometric)
          TextButton(
            onPressed: () {
              setState(() {
                _showPinInput = !_showPinInput;
                if (_showPinInput) {
                  _pinController.clear();
                  _pinFocusNode.requestFocus();
                }
              });
              ref.read(appLockProvider.notifier).clearError();
            },
            child: Text(
              _showPinInput ? 'Use Biometric Instead' : 'Use PIN Instead',
            ),
          ),
      ],
    );
  }

  Future<void> _handlePinSubmit() async {
    if (_pinController.text.length < 4) return;

    final success = await ref
        .read(appLockProvider.notifier)
        .unlockWithPin(_pinController.text);

    if (!success) {
      _pinController.clear();
      setState(() {});
    }
  }
}
