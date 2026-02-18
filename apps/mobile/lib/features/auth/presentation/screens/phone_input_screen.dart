import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/tekka_logo.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../router/app_router.dart';
import '../../application/auth_provider.dart';

/// Phone input screen for authentication
class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!value.isValidUgandaPhone) {
      return 'Enter a valid Ugandan phone number';
    }
    return null;
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.toE164Phone;

    try {
      await ref.read(authNotifierProvider.notifier).sendOtp(phone);

      if (mounted) {
        context.push(AppRoutes.otpVerification, extra: phone);
      }
    } catch (e) {
      if (mounted) {
        final message = e is AppException
            ? e.message
            : 'Something went wrong. Try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space10),

                // Logo
                const Center(child: TekkaLogo(height: 48)),

                const SizedBox(height: AppSpacing.space2),

                Text(
                  'Fashion Marketplace',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.space12),

                // Title
                Text(
                  'Enter your phone number',
                  style: AppTypography.headlineSmall,
                ),

                const SizedBox(height: AppSpacing.space2),

                Text(
                  'We\'ll send you a verification code',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Phone input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: _validatePhone,
                  inputFormatters: [
                    // Only allow digits (we handle the +256 prefix visually)
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: '712 345 678',
                    helperText: 'Enter with or without the leading 0',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇺🇬', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            AppConstants.ugandaCountryCode,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 24,
                            color: AppColors.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) => _onContinue(),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Continue button
                FilledButton(
                  onPressed: authState.isLoading ? null : _onContinue,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),

                const Spacer(),

                // Terms
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
