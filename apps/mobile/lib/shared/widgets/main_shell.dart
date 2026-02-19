import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../features/chat/application/chat_provider.dart';
import '../../router/app_router.dart';

/// Main shell widget with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNavBar(),
      extendBody: true,
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar();

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/browse')) return 0;
    if (location.startsWith('/saved')) return 1;
    if (location.startsWith('/chat')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, WidgetRef ref, int index) {
    // Home is always accessible (guest browsing)
    if (index == 0) {
      context.go(AppRoutes.home);
      return;
    }

    // All other tabs require authentication
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.push(AppRoutes.phoneInput);
      return;
    }

    switch (index) {
      case 1:
        context.go(AppRoutes.saved);
      case 2:
        context.push(AppRoutes.createListing);
      case 3:
        context.go(AppRoutes.chatList);
      case 4:
        context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _getCurrentIndex(context);
    final unreadCount = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => _onItemTapped(context, ref, 0),
              ),
              _NavItem(
                icon: Icons.favorite_border,
                activeIcon: Icons.favorite,
                label: 'Saved',
                isActive: currentIndex == 1,
                onTap: () => _onItemTapped(context, ref, 1),
              ),
              _SellButton(onTap: () => _onItemTapped(context, ref, 2)),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Chat',
                isActive: currentIndex == 3,
                onTap: () => _onItemTapped(context, ref, 3),
                badge: unreadCount,
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: currentIndex == 4,
                onTap: () => _onItemTapped(context, ref, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: AppSpacing.iconMedium,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isActive
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SellButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: AppColors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              'Sell',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
