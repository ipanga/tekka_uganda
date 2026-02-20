import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../router/app_router.dart';
import '../../application/auth_provider.dart';

/// OTP verification screen
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    AppConstants.otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    AppConstants.otpLength,
    (_) => FocusNode(),
  );

  bool _canResend = false;
  int _resendSeconds = AppConstants.otpResendDelay.inSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = AppConstants.otpResendDelay.inSeconds;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onOtpChanged(int index, String value) {
    // Handle auto-fill or paste: value may contain full OTP code
    if (index == 0 && value.length == AppConstants.otpLength) {
      for (int i = 0; i < AppConstants.otpLength; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes.last.requestFocus();
      _verifyOtp();
      return;
    }

    if (value.isNotEmpty && index < AppConstants.otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_otp.length == AppConstants.otpLength) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != AppConstants.otpLength) return;

    try {
      final user = await ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(_otp);

      if (mounted) {
        if (user.isOnboardingComplete) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.onboarding);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException
                  ? e.message
                  : 'Something went wrong. Try again.',
            ),
          ),
        );
        // Clear OTP fields
        for (final controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    try {
      await ref.read(authNotifierProvider.notifier).sendOtp(widget.phoneNumber);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OTP sent successfully')));
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException
                  ? e.message
                  : 'Something went wrong. Try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.space4),

              Text('Verify your number', style: AppTypography.headlineSmall),

              const SizedBox(height: AppSpacing.space2),

              Text(
                'Enter the 6-digit code sent to',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                widget.phoneNumber,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: AppSpacing.space8),

              // OTP input fields
              AutofillGroup(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    AppConstants.otpLength,
                    (index) => SizedBox(
                      width: 48,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: index == 0 ? AppConstants.otpLength : 1,
                        style: AppTypography.headlineMedium,
                        autofillHints: index == 0
                            ? const [AutofillHints.oneTimeCode]
                            : null,
                        decoration: const InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onOtpChanged(index, value),
                        onEditingComplete: () {
                          if (index < AppConstants.otpLength - 1) {
                            _focusNodes[index + 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Verify button
              if (authState.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _otp.length == AppConstants.otpLength
                      ? _verifyOtp
                      : null,
                  child: const Text('Verify'),
                ),

              const SizedBox(height: AppSpacing.space6),

              // Resend OTP
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _resendOtp,
                        child: const Text('Resend code'),
                      )
                    : Text(
                        'Resend code in ${_resendSeconds}s',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
