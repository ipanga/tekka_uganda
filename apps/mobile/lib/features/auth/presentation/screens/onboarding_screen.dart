import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/image_service_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/auth_provider.dart';

/// Onboarding screen for new users
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedLocation;
  File? _selectedImage;
  bool _isUploadingImage = false;

  final List<String> _locations = [
    'Kampala Central',
    'Kampala - Nakawa',
    'Kampala - Rubaga',
    'Kampala - Makindye',
    'Kampala - Kawempe',
    'Entebbe',
    'Jinja',
    'Mukono',
    'Wakiso',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onComplete() async {
    if (!_formKey.currentState!.validate()) return;

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

      await ref.read(authNotifierProvider.notifier).updateProfile(
            displayName: _nameController.text.trim(),
            location: _selectedLocation!,
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
          SnackBar(content: Text('$e')),
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
                    child: Text(_selectedImage != null ? 'Change photo' : 'Add photo (optional)'),
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

                // Location dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Where are you based?',
                  ),
                  items: _locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLocation = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your location';
                    }
                    return null;
                  },
                ),

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
