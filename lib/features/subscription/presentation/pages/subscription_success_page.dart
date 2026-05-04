import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class SubscriptionSuccessPage extends StatelessWidget {
  const SubscriptionSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.celebration_rounded, color: AppColors.proAccent, size: 96),
          const SizedBox(height: AppSpacing.xl),
          const Text('Pro unlocked!', style: AppTextStyles.displayLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          const Text('All NurseUp presentation features are now available.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(label: 'Explore 3D Anatomy', onPressed: () => context.go(AppRoutes.anatomy)),
        ]),
      ),
    );
  }
}

