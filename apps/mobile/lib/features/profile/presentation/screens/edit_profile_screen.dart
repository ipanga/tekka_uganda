import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/image_service_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../listing/application/category_provider.dart';
import '../../../listing/domain/entities/location.dart';
import '../../application/profile_provider.dart';

/// Edit profile screen
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isInitialized = false;
  File? _selectedImage;
  bool _isUploadingImage = false;

  // Location selection
  City? _selectedCity;
  Division? _selectedDivision;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    // Load cities when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFromUser() {
    if (_isInitialized) return;

    final user = ref.read(currentUserProvider);
    final categoryState = ref.read(categoryProvider);

    if (user != null && categoryState.cities.isNotEmpty) {
      _nameController.text = user.displayName ?? '';

      // Parse existing location to set city and division
      // Location format is "City" or "City - Division"
      if (user.location != null && user.location!.isNotEmpty) {
        final parts = user.location!.split(' - ');
        final cityName = parts.isNotEmpty ? parts[0].trim() : null;
        final divisionName = parts.length > 1 ? parts[1].trim() : null;

        if (cityName != null) {
          final city = categoryState.cities.firstWhere(
            (c) => c.name == cityName,
            orElse: () => categoryState.cities.first,
          );
          _selectedCity = city;

          if (divisionName != null && city.divisions.isNotEmpty) {
            final division = city.divisions.firstWhere(
              (d) => d.name == divisionName,
              orElse: () => city.divisions.first,
            );
            if (division.name == divisionName) {
              _selectedDivision = division;
            }
          }
        }
      }

      ref.read(profileUpdateProvider.notifier).initFromUser(user);
      _isInitialized = true;
    }
  }

  /// Build location string from selected city and division
  String _buildLocationString() {
    if (_selectedCity == null) return '';
    if (_selectedDivision != null) {
      return '${_selectedCity!.name} - ${_selectedDivision!.name}';
    }
    return _selectedCity!.name;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final updateState = ref.watch(profileUpdateProvider);
    final categoryState = ref.watch(categoryProvider);
    final cities = categoryState.activeCities;

    // Initialize controllers from user data (after cities are loaded)
    if (cities.isNotEmpty) {
      _initFromUser();
    }

    // Listen for save success
    ref.listen<ProfileUpdateState>(profileUpdateProvider, (prev, next) {
      if (next.isSaved && prev?.isSaved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: updateState.isLoading ? null : _saveProfile,
            child: updateState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: AppSpacing.space4),

            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (user?.photoUrl != null
                              ? CachedNetworkImageProvider(user!.photoUrl!)
                              : null),
                    child: (_selectedImage == null && user?.photoUrl == null)
                        ? const Icon(
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
                    child: GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space8),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              onChanged: (value) {
                ref.read(profileUpdateProvider.notifier).setDisplayName(value);
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // City dropdown
            DropdownButtonFormField<City>(
              value: _selectedCity,
              decoration: const InputDecoration(
                labelText: 'City/Town',
                hintText: 'Select your city',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              isExpanded: true,
              items: cities.map((city) {
                return DropdownMenuItem<City>(
                  value: city,
                  child: Text(city.name),
                );
              }).toList(),
              onChanged: (city) {
                setState(() {
                  _selectedCity = city;
                  _selectedDivision = null; // Reset division when city changes
                });
                ref
                    .read(profileUpdateProvider.notifier)
                    .setLocation(_buildLocationString());
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your city';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // Division dropdown (only show if city has divisions)
            if (_selectedCity != null &&
                _selectedCity!.activeDivisions.isNotEmpty)
              DropdownButtonFormField<Division>(
                value: _selectedDivision,
                decoration: const InputDecoration(
                  labelText: 'Division/Area (Optional)',
                  hintText: 'Select your area',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<Division>(
                    value: null,
                    child: Text('Select a division (optional)'),
                  ),
                  ..._selectedCity!.activeDivisions.map((division) {
                    return DropdownMenuItem<Division>(
                      value: division,
                      child: Text(division.name),
                    );
                  }),
                ],
                onChanged: (division) {
                  setState(() {
                    _selectedDivision = division;
                  });
                  ref
                      .read(profileUpdateProvider.notifier)
                      .setLocation(_buildLocationString());
                },
              ),

            const SizedBox(height: AppSpacing.space6),

            // Phone number (read-only)
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.cardRadius,
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Number',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          user?.phoneNumber ?? '',
                          style: AppTypography.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Verified',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Email (with verification status)
            GestureDetector(
              onTap: user?.emailVerified == true
                  ? null
                  : () => context.push(AppRoutes.emailVerification),
              child: Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.cardRadius,
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Address',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            user?.email ?? 'Not added',
                            style: AppTypography.bodyLarge.copyWith(
                              color: user?.email != null
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user?.emailVerified == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Verified',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.email != null ? 'Verify' : 'Add',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Member since (read-only)
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.cardRadius,
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Member Since',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          user != null ? _formatDate(user.createdAt) : '',
                          style: AppTypography.bodyLarge,
                        ),
                      ],
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

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
            if (_selectedImage != null ||
                ref.read(currentUserProvider)?.photoUrl != null)
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
                  ref.read(profileUpdateProvider.notifier).setPhotoUrl(null);
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

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Upload image if selected
    if (_selectedImage != null) {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final storageService = ref.read(storageServiceProvider);
      final photoUrl = await storageService.uploadProfileImage(
        imageFile: _selectedImage!,
        userId: user.uid,
      );

      setState(() {
        _isUploadingImage = false;
      });

      if (photoUrl != null) {
        ref.read(profileUpdateProvider.notifier).setPhotoUrl(photoUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        return;
      }
    }

    ref.read(profileUpdateProvider.notifier).save();
  }
}
