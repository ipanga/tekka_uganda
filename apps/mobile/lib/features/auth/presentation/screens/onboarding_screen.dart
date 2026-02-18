import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/image_service_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/auth_provider.dart';
import '../../../listing/application/category_provider.dart';
import '../../../listing/domain/entities/location.dart';

/// Onboarding screen for new users
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Location selection state (same pattern as create listing screen)
  City? _selectedCity;
  Division? _selectedDivision;

  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Load cities (same as create listing screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Format location string from selected city/division (same pattern as web registration)
  String? _getLocationString() {
    if (_selectedCity == null) return null;
    if (_selectedDivision != null) {
      return '${_selectedCity!.name}, ${_selectedDivision!.name}';
    }
    return _selectedCity!.name;
  }

  Future<void> _onComplete() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate city selection
    if (_selectedCity == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select your city')));
      return;
    }

    try {
      String? photoUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          setState(() {
            _isUploadingImage = true;
          });

          final storageService = ref.read(storageServiceProvider);
          photoUrl = await storageService.uploadProfileImage(
            imageFile: _selectedImage!,
            userId: user.uid,
          );

          setState(() {
            _isUploadingImage = false;
          });
        }
      }

      await ref
          .read(authNotifierProvider.notifier)
          .updateProfile(
            displayName: _nameController.text.trim(),
            location: _getLocationString()!,
            photoUrl: photoUrl,
          );

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
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

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.takePhoto();

    if (file != null) {
      final compressed = await imageService.compressImage(file);
      if (compressed != null) {
        setState(() {
          _selectedImage = compressed;
        });
      } else {
        setState(() {
          _selectedImage = file;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickImageFromGallery();

    if (file != null) {
      final compressed = await imageService.compressImage(file);
      if (compressed != null) {
        setState(() {
          _selectedImage = compressed;
        });
      } else {
        setState(() {
          _selectedImage = file;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: AppColors.outline,
                  color: AppColors.primary,
                ),

                const SizedBox(height: AppSpacing.space6),

                Text(
                  'Tell us about yourself',
                  style: AppTypography.headlineSmall,
                ),

                const SizedBox(height: AppSpacing.space2),

                Text(
                  'This helps buyers and sellers connect with you',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Profile photo (optional)
                Center(
                  child: GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primaryContainer,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : null,
                          child: _selectedImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space2),

                Center(
                  child: TextButton(
                    onPressed: _showPhotoOptions,
                    child: Text(
                      _selectedImage != null
                          ? 'Change photo'
                          : 'Add photo (optional)',
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space4),

                // Name input
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'How should we call you?',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.space4),

                // Location selection (same pattern as create listing screen)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'City', style: AppTypography.titleSmall),
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                if (categoryState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (categoryState.activeCities.isEmpty)
                  Text(
                    'Loading locations...',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: categoryState.activeCities.map((city) {
                      final isSelected = _selectedCity?.id == city.id;
                      return ChoiceChip(
                        label: Text(city.name),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCity = city;
                            _selectedDivision = null;
                          });
                        },
                        selectedColor: AppColors.primaryContainer,
                      );
                    }).toList(),
                  ),

                // Division selection (appears when city is selected)
                if (_selectedCity != null &&
                    _selectedCity!.activeDivisions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text('Area (Optional)', style: AppTypography.titleSmall),
                  const SizedBox(height: AppSpacing.space2),
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: _selectedCity!.activeDivisions.map((division) {
                      final isSelected = _selectedDivision?.id == division.id;
                      return FilterChip(
                        label: Text(division.name),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedDivision = isSelected ? null : division;
                          });
                        },
                        selectedColor: AppColors.primaryContainer,
                      );
                    }).toList(),
                  ),
                ],

                const Spacer(),

                // Complete button
                FilledButton(
                  onPressed: authState.isLoading ? null : _onComplete,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Get Started'),
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
