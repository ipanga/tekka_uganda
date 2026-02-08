import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../application/email_verification_provider.dart';

/// Screen for adding and verifying email address
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();
  Timer? _resendTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    // Reset state when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emailVerificationProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _secondsRemaining = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    await ref
        .read(emailVerificationProvider.notifier)
        .sendVerificationCode(email);
    _startResendTimer();
    _codeFocusNode.requestFocus();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }

    final success = await ref
        .read(emailVerificationProvider.notifier)
        .verifyCode(code);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      // Short delay to show success message
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.pop();
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(emailVerificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child:
              status.state == EmailVerificationState.codeSent ||
                  status.state == EmailVerificationState.verifying
              ? _buildCodeEntry(status)
              : _buildEmailEntry(status),
        ),
      ),
    );
  }

  Widget _buildEmailEntry(EmailVerificationStatus status) {
    final isLoading = status.state == EmailVerificationState.sendingCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.space4),

        // Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.email_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // Title
        Center(
          child: Text('Add Email Address', style: AppTypography.headlineSmall),
        ),

        const SizedBox(height: AppSpacing.space2),

        // Description
        Center(
          child: Text(
            'Add an email address to recover your account and receive important notifications.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: AppSpacing.space8),

        // Email input
        TextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _sendCode(),
        ),

        if (status.state == EmailVerificationState.error &&
            status.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    status.errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // Send code button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : _sendCode,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Send Verification Code'),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildCodeEntry(EmailVerificationStatus status) {
    final isLoading = status.state == EmailVerificationState.verifying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.space4),

        // Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.space6),

        // Title
        Center(
          child: Text(
            'Enter Verification Code',
            style: AppTypography.headlineSmall,
          ),
        ),

        const SizedBox(height: AppSpacing.space2),

        // Description
        Center(
          child: Text(
            'We sent a 6-digit code to\n${status.email}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: AppSpacing.space8),

        // Code input
        TextField(
          controller: _codeController,
          focusNode: _codeFocusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          enabled: !isLoading,
          maxLength: 6,
          style: AppTypography.headlineMedium.copyWith(letterSpacing: 8),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            if (value.length == 6) {
              _verifyCode();
            }
          },
        ),

        if (status.state == EmailVerificationState.error &&
            status.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    status.errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.space4),

        // Resend code
        Center(
          child: _secondsRemaining > 0
              ? Text(
                  'Resend code in $_secondsRemaining seconds',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              : TextButton(
                  onPressed: () {
                    ref.read(emailVerificationProvider.notifier).resendCode();
                    _startResendTimer();
                  },
                  child: const Text('Resend Code'),
                ),
        ),

        const Spacer(),

        // Verify button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : _verifyCode,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Verify Email'),
          ),
        ),

        const SizedBox(height: AppSpacing.space2),

        // Change email button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: isLoading
                ? null
                : () {
                    ref.read(emailVerificationProvider.notifier).reset();
                    _codeController.clear();
                  },
            child: const Text('Use Different Email'),
          ),
        ),

        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}
