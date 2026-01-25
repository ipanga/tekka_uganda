import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../application/pin_provider.dart';

/// Screen for changing or setting up PIN
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Start PIN change flow when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pinProvider.notifier).startPinChange();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pinStatus = ref.watch(pinProvider);

    // Listen for success state
    ref.listen<PinStatus>(pinProvider, (prev, next) {
      if (next.state == PinState.success && prev?.state != PinState.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pinStatus.hasPinSet ? 'PIN updated successfully' : 'PIN set successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle(pinStatus)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(pinProvider.notifier).cancel();
            context.pop();
          },
        ),
      ),
      body: _buildBody(pinStatus),
    );
  }

  String _getTitle(PinStatus status) {
    if (!status.hasPinSet && status.state == PinState.noPinSet) {
      return 'Set PIN';
    }
    switch (status.state) {
      case PinState.enteringCurrentPin:
        return 'Enter Current PIN';
      case PinState.enteringNewPin:
        return 'Enter New PIN';
      case PinState.confirmingNewPin:
        return 'Confirm New PIN';
      default:
        return 'Change PIN';
    }
  }

  Widget _buildBody(PinStatus status) {
    if (status.isLoading && status.state == PinState.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.space6),

        // Icon and instruction
        _buildHeader(status),

        const SizedBox(height: AppSpacing.space8),

        // PIN input
        _buildPinInput(status),

        if (status.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space4),
          _buildErrorMessage(status.errorMessage!),
        ],

        if (status.isLocked) ...[
          const SizedBox(height: AppSpacing.space4),
          _buildLockMessage(status),
        ],

        const SizedBox(height: AppSpacing.space6),

        // Action button
        _buildActionButton(status),

        const SizedBox(height: AppSpacing.space4),

        // Secondary actions
        _buildSecondaryActions(status),

        const SizedBox(height: AppSpacing.space8),

        // Info note
        _buildInfoNote(status),
      ],
    );
  }

  Widget _buildHeader(PinStatus status) {
    IconData icon;
    String title;
    String subtitle;

    switch (status.state) {
      case PinState.enteringCurrentPin:
        icon = Icons.lock_outline;
        title = 'Enter your current PIN';
        subtitle = 'To change your PIN, first verify your identity';
        break;
      case PinState.enteringNewPin:
        icon = Icons.pin_outlined;
        title = 'Create a new PIN';
        subtitle = 'Choose a 4-6 digit PIN that you\'ll remember';
        break;
      case PinState.confirmingNewPin:
        icon = Icons.check_circle_outline;
        title = 'Confirm your PIN';
        subtitle = 'Enter the same PIN again to confirm';
        break;
      case PinState.noPinSet:
        icon = Icons.security;
        title = 'Set up a PIN';
        subtitle = 'Add an extra layer of security to your account';
        break;
      default:
        icon = Icons.lock_outline;
        title = 'PIN';
        subtitle = '';
    }

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          title,
          style: AppTypography.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildPinInput(PinStatus status) {
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

        // Hidden text field for input
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {});
              // Auto-submit when 4-6 digits entered
              if (value.length >= 4) {
                // Optionally auto-submit
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
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockMessage(PinStatus status) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              'Account locked. Try again in ${status.remainingLockSeconds ~/ 60} minutes.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(PinStatus status) {
    final isEnabled = _pinController.text.length >= 4 &&
        !status.isLoading &&
        !status.isLocked;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isEnabled ? () => _handleSubmit(status) : null,
        child: status.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_getButtonText(status)),
      ),
    );
  }

  String _getButtonText(PinStatus status) {
    switch (status.state) {
      case PinState.enteringCurrentPin:
        return 'Verify';
      case PinState.enteringNewPin:
        return 'Continue';
      case PinState.confirmingNewPin:
        return 'Set PIN';
      case PinState.noPinSet:
        return 'Set PIN';
      default:
        return 'Continue';
    }
  }

  Future<void> _handleSubmit(PinStatus status) async {
    final pin = _pinController.text;

    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits')),
      );
      return;
    }

    switch (status.state) {
      case PinState.enteringCurrentPin:
        await ref.read(pinProvider.notifier).verifyCurrentPin(pin);
        _pinController.clear();
        setState(() {});
        break;
      case PinState.enteringNewPin:
      case PinState.noPinSet:
        ref.read(pinProvider.notifier).setNewPin(pin);
        _pinController.clear();
        setState(() {});
        break;
      case PinState.confirmingNewPin:
        await ref.read(pinProvider.notifier).confirmNewPin(pin);
        _pinController.clear();
        setState(() {});
        break;
      default:
        break;
    }
  }

  Widget _buildSecondaryActions(PinStatus status) {
    if (status.state == PinState.confirmingNewPin) {
      return TextButton(
        onPressed: () {
          _pinController.clear();
          ref.read(pinProvider.notifier).startPinChange();
          setState(() {});
        },
        child: const Text('Start Over'),
      );
    }

    if (status.hasPinSet && status.state == PinState.enteringCurrentPin) {
      return TextButton(
        onPressed: () => _showForgotPinDialog(),
        child: const Text('Forgot PIN?'),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoNote(PinStatus status) {
    String note;

    if (!status.hasPinSet) {
      note = 'Your PIN will be required when making sensitive changes to your account or accessing private information.';
    } else {
      note = 'Keep your PIN private. Never share it with anyone, including Tekka support.';
    }

    return Container(
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
            Icons.info_outline,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              note,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you\'ve forgotten your PIN, you\'ll need to sign out and sign back in to reset it.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'This is a security measure to protect your account.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
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
              Navigator.pop(context);
              // Could trigger sign out here if needed
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
