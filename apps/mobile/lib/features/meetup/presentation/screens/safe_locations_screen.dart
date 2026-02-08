import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../application/meetup_provider.dart';
import '../../domain/entities/meetup_location.dart';

/// Screen displaying safe meetup locations
class SafeLocationsScreen extends ConsumerStatefulWidget {
  const SafeLocationsScreen({super.key});

  @override
  ConsumerState<SafeLocationsScreen> createState() =>
      _SafeLocationsScreenState();
}

class _SafeLocationsScreenState extends ConsumerState<SafeLocationsScreen> {
  MeetupLocationType? _selectedType;
  String? _selectedArea;

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(safeLocationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Safe Meetup Locations')),
      body: locationsAsync.when(
        data: (locations) {
          // Get unique areas
          final areas = locations.map((l) => l.area).toSet().toList()..sort();

          // Filter locations
          var filtered = locations;
          if (_selectedType != null) {
            filtered = filtered.where((l) => l.type == _selectedType).toList();
          }
          if (_selectedArea != null) {
            filtered = filtered.where((l) => l.area == _selectedArea).toList();
          }

          return Column(
            children: [
              // Filters
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Column(
                  children: [
                    // Type filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All Types',
                            selected: _selectedType == null,
                            onSelected: () =>
                                setState(() => _selectedType = null),
                          ),
                          ...MeetupLocationType.values.map(
                            (type) => _FilterChip(
                              label: type.displayName,
                              selected: _selectedType == type,
                              onSelected: () =>
                                  setState(() => _selectedType = type),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    // Area dropdown
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedArea,
                      decoration: InputDecoration(
                        labelText: 'Filter by Area',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Areas'),
                        ),
                        ...areas.map(
                          (area) =>
                              DropdownMenuItem(value: area, child: Text(area)),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedArea = value),
                    ),
                  ],
                ),
              ),

              // Results count
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} location${filtered.length != 1 ? 's' : ''} found',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Locations list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 64,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.space4),
                            Text(
                              'No locations found',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space2),
                            Text(
                              'Try adjusting your filters',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: AppSpacing.screenPadding,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final location = filtered[index];
                          return _LocationCard(location: location);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Failed to load locations',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.refresh(safeLocationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryContainer,
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.onSurface,
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final MeetupLocation location;

  const _LocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: _getTypeColor(location.type).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd - 1),
                topRight: Radius.circular(AppSpacing.radiusMd - 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getTypeIcon(location.type),
                  size: 18,
                  color: _getTypeColor(location.type),
                ),
                const SizedBox(width: 8),
                Text(
                  location.type.displayName,
                  style: AppTypography.labelMedium.copyWith(
                    color: _getTypeColor(location.type),
                  ),
                ),
                const Spacer(),
                if (location.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          size: 12,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and area
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location.name, style: AppTypography.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            location.address,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (location.area.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_city,
                                  size: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  location.area,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Usage count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${location.usageCount}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Description
                if (location.description != null &&
                    location.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    location.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],

                // Amenities
                if (location.amenities.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: location.amenities.map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getAmenityIcon(amenity),
                              size: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              amenity,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: AppSpacing.space3),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMaps(
                          location.latitude,
                          location.longitude,
                          location.name,
                        ),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('View on Map'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _getDirections(
                          location.latitude,
                          location.longitude,
                        ),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(MeetupLocationType type) {
    switch (type) {
      case MeetupLocationType.mall:
        return AppColors.primary;
      case MeetupLocationType.cafe:
        return const Color(0xFF8B4513); // Brown
      case MeetupLocationType.publicSpace:
        return AppColors.success;
      case MeetupLocationType.petrolStation:
        return const Color(0xFFFF6B00); // Orange
      case MeetupLocationType.bank:
        return AppColors.secondary;
      case MeetupLocationType.policeStation:
        return const Color(0xFF0066CC); // Blue
      case MeetupLocationType.other:
        return AppColors.onSurfaceVariant;
    }
  }

  IconData _getTypeIcon(MeetupLocationType type) {
    switch (type) {
      case MeetupLocationType.mall:
        return Icons.local_mall;
      case MeetupLocationType.cafe:
        return Icons.local_cafe;
      case MeetupLocationType.publicSpace:
        return Icons.park;
      case MeetupLocationType.petrolStation:
        return Icons.local_gas_station;
      case MeetupLocationType.bank:
        return Icons.account_balance;
      case MeetupLocationType.policeStation:
        return Icons.local_police;
      case MeetupLocationType.other:
        return Icons.location_on;
    }
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'cctv':
        return Icons.videocam;
      case 'security':
        return Icons.security;
      case 'parking':
        return Icons.local_parking;
      case 'wifi':
        return Icons.wifi;
      case 'restroom':
        return Icons.wc;
      case 'food':
        return Icons.restaurant;
      case 'atm':
        return Icons.atm;
      default:
        return Icons.check_circle_outline;
    }
  }

  Future<void> _openMaps(double lat, double lng, String label) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getDirections(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
