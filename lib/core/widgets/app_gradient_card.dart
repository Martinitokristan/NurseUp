import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppGradientCard extends StatelessWidget {
  const AppGradientCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.lg), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), Color(0xFFEAF7FF), Color(0xFFD6EEFF)]),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: child,
      ),
    );
  }
}
