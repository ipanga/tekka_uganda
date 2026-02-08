import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../application/location_provider.dart';

/// Screen for selecting default location
class DefaultLocationScreen extends ConsumerWidget {
  const DefaultLocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationPreferencesProvider);
    final groupedRegions = UgandaRegionX.grouped;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Default Location')),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Info section
          Padding(
            padding: AppSpacing.screenPadding,
            child: Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: AppSpacing.cardRadius,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Default Location',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This location will be used as your default when browsing listings and creating new items for sale.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Current selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppSpacing.cardRadius,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Location',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        locationState.selectedLocation.displayName,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    locationState.selectedLocation.region,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Regions
          ...groupedRegions.entries.map((entry) {
            final regionName = entry.key;
            final locations = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RegionHeader(title: regionName),
                Container(
                  color: AppColors.surface,
                  child: Column(
                    children: locations.asMap().entries.map((locationEntry) {
                      final index = locationEntry.key;
                      final location = locationEntry.value;
                      final isSelected =
                          locationState.selectedLocation == location;
                      final isLast = index == locations.length - 1;

                      return Column(
                        children: [
                          _LocationTile(
                            location: location,
                            isSelected: isSelected,
                            isLoading: locationState.isLoading,
                            onTap: () =>
                                _selectLocation(context, ref, location),
                          ),
                          if (!isLast) const Divider(height: 1, indent: 56),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
            );
          }),

          // Note
          Padding(
            padding: AppSpacing.screenPadding,
            child: Container(
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
                      'You can always change your location when creating a listing or searching for items.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space10),
        ],
      ),
    );
  }

  Future<void> _selectLocation(
    BuildContext context,
    WidgetRef ref,
    UgandaRegion location,
  ) async {
    final currentLocation = ref
        .read(locationPreferencesProvider)
        .selectedLocation;

    if (currentLocation == location) return;

    final success = await ref
        .read(locationPreferencesProvider.notifier)
        .setLocation(location);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Default location set to ${location.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update location'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _RegionHeader extends StatelessWidget {
  const _RegionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space2,
        AppSpacing.space4,
        AppSpacing.space2,
      ),
      child: Row(
        children: [
          Icon(
            _getRegionIcon(title),
            size: 16,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            '$title Region',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRegionIcon(String region) {
    switch (region) {
      case 'Central':
        return Icons.location_city;
      case 'Eastern':
        return Icons.wb_sunny_outlined;
      case 'Western':
        return Icons.landscape_outlined;
      case 'Northern':
        return Icons.terrain_outlined;
      default:
        return Icons.place_outlined;
    }
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.location,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  final UgandaRegion location;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.outline.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.location_on_outlined,
          color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
      title: Text(
        location.displayName,
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.onSurface,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.white, size: 16),
            )
          : null,
      onTap: isLoading ? null : onTap,
    );
  }
}
