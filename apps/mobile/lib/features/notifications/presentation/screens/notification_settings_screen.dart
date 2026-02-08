import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../application/notification_provider.dart';
import '../../domain/entities/notification_preferences.dart';

/// Notification settings screen
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notification Settings')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load settings', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () =>
                    ref.invalidate(notificationPreferencesStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (prefs) => _NotificationSettingsContent(prefs: prefs),
      ),
    );
  }
}

class _NotificationSettingsContent extends ConsumerWidget {
  const _NotificationSettingsContent({required this.prefs});

  final NotificationPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationPreferencesNotifierProvider.notifier);

    return ListView(
      children: [
        const SizedBox(height: AppSpacing.space4),

        // General notifications section
        _SectionHeader(title: 'General'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _SettingsToggle(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive alerts on your device',
                value: prefs.pushEnabled,
                onChanged: (value) => notifier.setPushEnabled(value),
              ),
              _SettingsToggle(
                icon: Icons.mail_outline,
                title: 'Email Notifications',
                subtitle: 'Receive updates via email',
                value: prefs.emailEnabled,
                onChanged: (value) => notifier.setEmailEnabled(value),
              ),
              _SettingsToggle(
                icon: Icons.campaign_outlined,
                title: 'Marketing',
                subtitle: 'Receive promotional offers and tips',
                value: prefs.marketingEnabled,
                onChanged: (value) => notifier.setMarketingEnabled(value),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Push notification types section
        _SectionHeader(title: 'Push Notification Types'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _SettingsToggle(
                icon: Icons.chat_bubble_outline,
                title: 'Messages',
                subtitle: 'New messages from buyers and sellers',
                value: prefs.messageNotifications,
                enabled: prefs.pushEnabled,
                onChanged: (value) => notifier.setMessageNotifications(value),
              ),
              _SettingsToggle(
                icon: Icons.star_outline,
                title: 'Reviews',
                subtitle: 'New reviews on your profile',
                value: prefs.reviewNotifications,
                enabled: prefs.pushEnabled,
                onChanged: (value) => notifier.setReviewNotifications(value),
              ),
              _SettingsToggle(
                icon: Icons.inventory_2_outlined,
                title: 'Listings',
                subtitle: 'Updates on your listings status',
                value: prefs.listingNotifications,
                enabled: prefs.pushEnabled,
                onChanged: (value) => notifier.setListingNotifications(value),
              ),
              _SettingsToggle(
                icon: Icons.info_outline,
                title: 'System',
                subtitle: 'Important app updates and alerts',
                value: prefs.systemNotifications,
                enabled: prefs.pushEnabled,
                onChanged: (value) => notifier.setSystemNotifications(value),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Do Not Disturb section
        _SectionHeader(title: 'Do Not Disturb'),
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _SettingsToggle(
                icon: Icons.do_not_disturb_on_outlined,
                title: 'Do Not Disturb',
                subtitle: 'Silence notifications during set hours',
                value: prefs.doNotDisturb,
                enabled: prefs.pushEnabled,
                onChanged: (value) => notifier.setDoNotDisturb(value),
              ),
              if (prefs.doNotDisturb && prefs.pushEnabled)
                _DndTimeSelector(
                  startHour: prefs.dndStartHour ?? 22,
                  endHour: prefs.dndEndHour ?? 7,
                  onChanged: (start, end) {
                    notifier.setDoNotDisturb(
                      true,
                      startHour: start,
                      endHour: end,
                    );
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Info section
        Padding(
          padding: AppSpacing.screenPadding,
          child: Text(
            'Tip: Enabling Do Not Disturb will silence notifications during the selected hours, but you\'ll still receive them when the period ends.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.space10),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

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
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? AppColors.onSurfaceVariant : AppColors.gray400,
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: enabled ? AppColors.onSurface : AppColors.gray400,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: enabled ? AppColors.onSurfaceVariant : AppColors.gray400,
        ),
      ),
      trailing: Switch(
        value: value && enabled,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

class _DndTimeSelector extends StatelessWidget {
  const _DndTimeSelector({
    required this.startHour,
    required this.endHour,
    required this.onChanged,
  });

  final int startHour;
  final int endHour;
  final void Function(int start, int end) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        AppSpacing.space4,
      ),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.3),
          borderRadius: AppSpacing.cardRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: _TimePickerButton(
                label: 'From',
                hour: startHour,
                onTap: () => _showTimePicker(context, startHour, (hour) {
                  onChanged(hour, endHour);
                }),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.space3),
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
            Expanded(
              child: _TimePickerButton(
                label: 'To',
                hour: endHour,
                onTap: () => _showTimePicker(context, endHour, (hour) {
                  onChanged(startHour, hour);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(
    BuildContext context,
    int currentHour,
    ValueChanged<int> onSelected,
  ) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    ).then((time) {
      if (time != null) {
        onSelected(time.hour);
      }
    });
  }
}

class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({
    required this.label,
    required this.hour,
    required this.onTap,
  });

  final String label;
  final int hour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(_formatHour(hour), style: AppTypography.titleMedium),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }
}
