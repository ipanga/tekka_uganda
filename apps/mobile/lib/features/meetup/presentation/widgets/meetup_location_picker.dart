import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../application/meetup_provider.dart';
import '../../domain/entities/meetup_location.dart';

/// Bottom sheet for picking a safe meetup location
class MeetupLocationPicker extends ConsumerStatefulWidget {
  const MeetupLocationPicker({
    super.key,
    this.initialArea,
    required this.onLocationSelected,
  });

  final String? initialArea;
  final void Function(MeetupLocation location) onLocationSelected;

  @override
  ConsumerState<MeetupLocationPicker> createState() => _MeetupLocationPickerState();
}

class _MeetupLocationPickerState extends ConsumerState<MeetupLocationPicker> {
  String? _selectedArea;

  @override
  void initState() {
    super.initState();
    _selectedArea = widget.initialArea;
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = _selectedArea != null
        ? ref.watch(locationsByAreaProvider(_selectedArea!))
        : ref.watch(safeLocationsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  'Suggest Safe Meetup Location',
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
          ),

          // Area filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Row(
              children: [
                _AreaChip(
                  label: 'All',
                  isSelected: _selectedArea == null,
                  onTap: () => setState(() => _selectedArea = null),
                ),
                const SizedBox(width: AppSpacing.space2),
                _AreaChip(
                  label: 'Kampala CBD',
                  isSelected: _selectedArea == 'Kampala CBD',
                  onTap: () => setState(() => _selectedArea = 'Kampala CBD'),
                ),
                const SizedBox(width: AppSpacing.space2),
                _AreaChip(
                  label: 'Ntinda',
                  isSelected: _selectedArea == 'Ntinda',
                  onTap: () => setState(() => _selectedArea = 'Ntinda'),
                ),
                const SizedBox(width: AppSpacing.space2),
                _AreaChip(
                  label: 'Kololo',
                  isSelected: _selectedArea == 'Kololo',
                  onTap: () => setState(() => _selectedArea = 'Kololo'),
                ),
                const SizedBox(width: AppSpacing.space2),
                _AreaChip(
                  label: 'Entebbe',
                  isSelected: _selectedArea == 'Entebbe',
                  onTap: () => setState(() => _selectedArea = 'Entebbe'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space3),
          const Divider(height: 1),

          // Locations list
          Expanded(
            child: locationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(height: AppSpacing.space2),
                    Text('Failed to load locations: $e'),
                  ],
                ),
              ),
              data: (locations) {
                if (locations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        Text(
                          'No locations found',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  itemCount: locations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return _LocationCard(
                      location: location,
                      onTap: () {
                        widget.onLocationSelected(location);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.onTap,
  });

  final MeetupLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                _getLocationTypeIcon(location.type),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),

            // Location details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          location.name,
                          style: AppTypography.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (location.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 12,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Verified',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.address,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      location.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (location.amenities.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: AppSpacing.space1,
                      runSpacing: AppSpacing.space1,
                      children: location.amenities.take(3).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            amenity,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.space2),
            Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLocationTypeIcon(MeetupLocationType type) {
    switch (type) {
      case MeetupLocationType.mall:
        return Icons.store;
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
        return Icons.place;
    }
  }
}

/// Shows the meetup location picker bottom sheet
Future<MeetupLocation?> showMeetupLocationPicker(
  BuildContext context, {
  String? initialArea,
}) async {
  MeetupLocation? selectedLocation;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MeetupLocationPicker(
      initialArea: initialArea,
      onLocationSelected: (location) {
        selectedLocation = location;
      },
    ),
  );

  return selectedLocation;
}
