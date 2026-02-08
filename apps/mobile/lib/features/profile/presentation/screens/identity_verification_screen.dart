import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/image_service_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/identity_verification_provider.dart';

/// Screen for identity verification with document upload
class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _fullNameController = TextEditingController();
  DateTime? _dateOfBirth;
  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _documentNumberController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(identityVerificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Identity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (status.state == IdentityVerificationState.enteringDetails) {
              ref.read(identityVerificationProvider.notifier).goBack();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(child: _buildContent(status)),
    );
  }

  Widget _buildContent(IdentityVerificationStatus status) {
    // If already verified or under review
    if (status.state == IdentityVerificationState.verified) {
      return _buildVerifiedView(status);
    }
    if (status.state == IdentityVerificationState.underReview ||
        status.state == IdentityVerificationState.submitted) {
      return _buildUnderReviewView(status);
    }
    if (status.state == IdentityVerificationState.rejected) {
      return _buildRejectedView(status);
    }

    // Document selection or details entry
    if (status.state == IdentityVerificationState.enteringDetails &&
        status.documentType != null) {
      return _buildDetailsForm(status);
    }

    return _buildDocumentSelection();
  }

  Widget _buildDocumentSelection() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Header
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.badge_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          Center(
            child: Text(
              'Verify Your Identity',
              style: AppTypography.headlineSmall,
            ),
          ),

          const SizedBox(height: AppSpacing.space2),

          Center(
            child: Text(
              'Choose a valid ID document to verify your identity. This helps build trust with other users.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.space8),

          Text('Select Document Type', style: AppTypography.titleMedium),

          const SizedBox(height: AppSpacing.space4),

          // Document type options
          ...IdDocumentType.values.map(
            (type) => _DocumentTypeCard(
              type: type,
              onTap: () {
                ref
                    .read(identityVerificationProvider.notifier)
                    .setDocumentType(type);
              },
            ),
          ),

          const Spacer(),

          // Info note
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    'Your documents are securely stored and only used for verification purposes.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }

  Widget _buildDetailsForm(IdentityVerificationStatus status) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Document type indicator
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Row(
              children: [
                Icon(Icons.badge_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  status.documentType!.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(identityVerificationProvider.notifier).goBack();
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          Text('Personal Details', style: AppTypography.titleMedium),

          const SizedBox(height: AppSpacing.space4),

          // Full name
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name (as on document)',
              hintText: 'Enter your full legal name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (value.trim().length < 3) {
                return 'Name must be at least 3 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // Document number
          TextFormField(
            controller: _documentNumberController,
            decoration: InputDecoration(
              labelText: '${status.documentType!.displayName} Number',
              hintText: 'Enter document number',
              prefixIcon: const Icon(Icons.numbers),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter document number';
              }
              if (value.trim().length < 5) {
                return 'Invalid document number';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // Date of birth
          GestureDetector(
            onTap: _selectDateOfBirth,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _dateOfBirth != null
                    ? DateFormat('dd MMM yyyy').format(_dateOfBirth!)
                    : 'Select date of birth',
                style: AppTypography.bodyLarge.copyWith(
                  color: _dateOfBirth != null
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          Text('Document Photos', style: AppTypography.titleMedium),

          const SizedBox(height: AppSpacing.space2),

          Text(
            'Take clear photos of your document. Make sure all details are visible.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Front of document
          _ImageUploadCard(
            title: 'Front of Document',
            subtitle: 'Photo side with your details',
            icon: Icons.credit_card,
            image: _frontImage,
            isRequired: true,
            onTap: () => _pickImage((file) {
              setState(() => _frontImage = file);
            }),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Back of document
          _ImageUploadCard(
            title: 'Back of Document',
            subtitle: 'Back side (if applicable)',
            icon: Icons.credit_card,
            image: _backImage,
            isRequired: false,
            onTap: () => _pickImage((file) {
              setState(() => _backImage = file);
            }),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Selfie
          _ImageUploadCard(
            title: 'Selfie with Document',
            subtitle: 'Hold your ID next to your face',
            icon: Icons.face,
            image: _selfieImage,
            isRequired: false,
            onTap: () => _takeSelfie(),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isUploading ? null : _submitVerification,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Submit for Verification'),
            ),
          ),

          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }

  Widget _buildVerifiedView(IdentityVerificationStatus status) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                size: 60,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text('Identity Verified', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Your identity has been successfully verified. You now have a fully verified account.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (status.verifiedAt != null) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Verified on ${DateFormat('dd MMM yyyy').format(status.verifiedAt!)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderReviewView(IdentityVerificationStatus status) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top,
                size: 60,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              'Verification In Progress',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Your documents are being reviewed. This usually takes 1-2 business days. We\'ll notify you once verification is complete.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (status.submittedAt != null) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Submitted on ${DateFormat('dd MMM yyyy').format(status.submittedAt!)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedView(IdentityVerificationStatus status) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_outlined,
                size: 60,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text('Verification Rejected', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Your verification was not approved. Please try again with valid documents.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (status.rejectionReason != null) ...[
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.cardRadius,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        status.rejectionReason!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(identityVerificationProvider.notifier).reset();
                },
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final minAge = DateTime(now.year - 18, now.month, now.day);
    final maxAge = DateTime(now.year - 100, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? minAge,
      firstDate: maxAge,
      lastDate: minAge,
      helpText: 'Select your date of birth',
    );

    if (date != null) {
      setState(() => _dateOfBirth = date);
    }
  }

  Future<void> _pickImage(void Function(File) onSelected) async {
    final imageService = ref.read(imageServiceProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await imageService.takePhoto();
                if (file != null) {
                  final compressed = await imageService.compressImage(file);
                  onSelected(compressed ?? file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await imageService.pickImageFromGallery();
                if (file != null) {
                  final compressed = await imageService.compressImage(file);
                  onSelected(compressed ?? file);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takeSelfie() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.takePhoto();
    if (file != null) {
      final compressed = await imageService.compressImage(file);
      setState(() => _selfieImage = compressed ?? file);
    }
  }

  Future<void> _submitVerification() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    if (_frontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the front of your document'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('Not authenticated');
      }

      final storageService = ref.read(storageServiceProvider);
      final notifier = ref.read(identityVerificationProvider.notifier);

      // Upload front image
      final frontUrl = await storageService.uploadImage(
        imageFile: _frontImage!,
        path: 'identity_verification/${user.uid}/front.jpg',
      );
      if (frontUrl != null) {
        notifier.setFrontImage(frontUrl);
      }

      // Upload back image if provided
      if (_backImage != null) {
        final backUrl = await storageService.uploadImage(
          imageFile: _backImage!,
          path: 'identity_verification/${user.uid}/back.jpg',
        );
        if (backUrl != null) {
          notifier.setBackImage(backUrl);
        }
      }

      // Upload selfie if provided
      if (_selfieImage != null) {
        final selfieUrl = await storageService.uploadImage(
          imageFile: _selfieImage!,
          path: 'identity_verification/${user.uid}/selfie.jpg',
        );
        if (selfieUrl != null) {
          notifier.setSelfie(selfieUrl);
        }
      }

      // Set document details
      notifier.setDocumentDetails(
        documentNumber: _documentNumberController.text.trim(),
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
      );

      // Submit verification
      final success = await notifier.submitVerification();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

class _DocumentTypeCard extends StatelessWidget {
  final IdDocumentType type;
  final VoidCallback onTap;

  const _DocumentTypeCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.cardRadius,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.displayName, style: AppTypography.titleSmall),
                    Text(
                      type.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? image;
  final bool isRequired;
  final VoidCallback onTap;

  const _ImageUploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.image,
    required this.isRequired,
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
            color: image != null ? AppColors.success : AppColors.outline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: image != null
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image!,
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                      ),
                    )
                  : Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppTypography.titleSmall),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              image != null ? Icons.check_circle : Icons.add_a_photo_outlined,
              color: image != null ? AppColors.success : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
