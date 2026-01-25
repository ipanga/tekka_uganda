import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../application/meetup_provider.dart';
import '../../domain/entities/meetup_location.dart';
import 'meetup_location_picker.dart';

/// Bottom sheet for scheduling a complete meetup
class ScheduleMeetupSheet extends ConsumerStatefulWidget {
  const ScheduleMeetupSheet({
    super.key,
    required this.chatId,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.onMeetupScheduled,
  });

  final String chatId;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final void Function(ScheduledMeetup meetup) onMeetupScheduled;

  @override
  ConsumerState<ScheduleMeetupSheet> createState() => _ScheduleMeetupSheetState();
}

class _ScheduleMeetupSheetState extends ConsumerState<ScheduleMeetupSheet> {
  MeetupLocation? _selectedLocation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime? get _combinedDateTime {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  bool get _isValid => _selectedLocation != null && _combinedDateTime != null;

  @override
  Widget build(BuildContext context) {
    final params = ScheduleMeetupParams(
      chatId: widget.chatId,
      listingId: widget.listingId,
      buyerId: widget.buyerId,
      sellerId: widget.sellerId,
    );
    final meetupState = ref.watch(scheduleMeetupProvider(params));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  'Schedule Meetup',
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location section
                  Text(
                    'Location',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  _buildLocationSelector(),

                  const SizedBox(height: AppSpacing.space6),

                  // Date section
                  Text(
                    'Date',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  _buildDateSelector(),

                  const SizedBox(height: AppSpacing.space6),

                  // Time section
                  Text(
                    'Time',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  _buildTimeSelector(),

                  const SizedBox(height: AppSpacing.space6),

                  // Notes section
                  Text(
                    'Notes (optional)',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Any additional details...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    maxLines: 2,
                  ),

                  // Error message
                  if (meetupState.error != null) ...[
                    const SizedBox(height: AppSpacing.space4),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: Text(
                              meetupState.error!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom action
          Container(
            padding: AppSpacing.screenPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: AppTheme.stickyShadow,
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isValid && !meetupState.isLoading
                      ? () => _scheduleMeetup(params)
                      : null,
                  child: meetupState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Send Meetup Proposal'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return GestureDetector(
      onTap: _selectLocation,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: _selectedLocation != null
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _selectedLocation != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLocation!.name,
                          style: AppTypography.bodyLarge,
                        ),
                        Text(
                          _selectedLocation!.address,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Select a safe meetup location',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: _selectedDate != null
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? _formatDate(_selectedDate!)
                    : 'Select a date',
                style: AppTypography.bodyMedium.copyWith(
                  color: _selectedDate != null
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: _selectedTime != null
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                _selectedTime != null
                    ? _formatTime(_selectedTime!)
                    : 'Select a time',
                style: AppTypography.bodyMedium.copyWith(
                  color: _selectedTime != null
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLocation() async {
    final location = await showMeetupLocationPicker(context);
    if (location != null) {
      setState(() {
        _selectedLocation = location;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _scheduleMeetup(ScheduleMeetupParams params) async {
    if (!_isValid || _selectedLocation == null || _combinedDateTime == null) return;

    final notifier = ref.read(scheduleMeetupProvider(params).notifier);
    notifier.selectLocation(_selectedLocation!);
    notifier.selectDate(_combinedDateTime!);
    if (_notesController.text.isNotEmpty) {
      notifier.updateNotes(_notesController.text);
    }

    final meetup = await notifier.scheduleMeetup();
    if (meetup != null && mounted) {
      widget.onMeetupScheduled(meetup);
      Navigator.pop(context);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == tomorrow.year &&
               date.month == tomorrow.month &&
               date.day == tomorrow.day) {
      return 'Tomorrow';
    }

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// Shows the schedule meetup bottom sheet
Future<ScheduledMeetup?> showScheduleMeetupSheet(
  BuildContext context, {
  required String chatId,
  required String listingId,
  required String buyerId,
  required String sellerId,
}) async {
  ScheduledMeetup? result;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ScheduleMeetupSheet(
      chatId: chatId,
      listingId: listingId,
      buyerId: buyerId,
      sellerId: sellerId,
      onMeetupScheduled: (meetup) {
        result = meetup;
      },
    ),
  );

  return result;
}
