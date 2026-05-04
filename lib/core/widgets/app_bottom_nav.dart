import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 26, offset: const Offset(0, 12))],
          border: Border.all(color: isDark ? scheme.outline : const Color(0xFFEAF3FF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Home', selected: index == 0, onTap: () => context.go(AppRoutes.home)),
            _NavItem(icon: Icons.folder_rounded, label: 'Library', selected: index == 1, onTap: () => context.go(AppRoutes.files)),
            _NavPlusButton(onTap: () => context.push(AppRoutes.upload)),
            _NavItem(icon: Icons.view_in_ar_rounded, label: '3D', selected: index == 2, onTap: () => context.go(AppRoutes.anatomy)),
            _NavItem(icon: Icons.person_rounded, label: 'Profile', selected: index == 3, onTap: () => context.go(AppRoutes.profile)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.55);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

class _NavPlusButton extends StatelessWidget {
  const _NavPlusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
