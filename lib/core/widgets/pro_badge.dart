import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.proSurface, borderRadius: BorderRadius.circular(AppSpacing.radiusFull), border: Border.all(color: AppColors.proAccent)),
      child: Text('PRO', style: AppTextStyles.overline.copyWith(color: AppColors.proAccent, fontWeight: FontWeight.w800)),
    );
  }
}

