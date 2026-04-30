import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';
import '../../core/theme/theme.dart';

/// Banner shown at the top of the app when offline.
///
/// Also briefly flashes a "Back online" confirmation when connectivity
/// returns, so users know the pending actions they queued will be retried.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  Timer? _restoredTimer;
  bool _showRestored = false;

  @override
  void dispose() {
    _restoredTimer?.cancel();
    super.dispose();
  }

  void _onRestored() {
    _restoredTimer?.cancel();
    setState(() => _showRestored = true);
    _restoredTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showRestored = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(connectivityRestoredProvider, (_, next) {
      next.whenData((_) => _onRestored());
    });

    final isConnected = ref.watch(isConnectedProvider);

    if (!isConnected) {
      return _Banner(
        color: AppColors.gray900,
        icon: Icons.wifi_off,
        text: 'No internet connection',
      );
    }
    if (_showRestored) {
      return _Banner(
        color: AppColors.primary,
        icon: Icons.wifi,
        text: 'Back online',
      );
    }
    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTypography.labelMedium.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
