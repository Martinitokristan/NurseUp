import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/usage_model.dart';

class UsageTransparencyCard extends StatelessWidget {
  const UsageTransparencyCard({super.key, required this.usage, this.onUpgrade});

  final UsageModel usage;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final limit = usage.getWeeklyLimit();
    final remaining = usage.getRemainingWords();
    final percentage = usage.getUsagePercentage();
    final isPro = usage.tier == 'pro';
    final isLimitReached = usage.isLimitReached();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Weekly Usage', style: AppTextStyles.h3),
                const Spacer(),
                Text(isPro ? 'Pro Plan ⭐' : 'Free Plan', style: AppTextStyles.bodySmall.copyWith(color: isPro ? AppColors.primary : AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Resets Monday', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            Text('Words used this week', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: percentage.clamp(0.0, 1.0), color: _getProgressColor(percentage), backgroundColor: AppColors.primarySurface),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${usage.wordsUsedThisWeek} / $limit words', style: AppTextStyles.bodySmall),
                Text('${(percentage * 100).toInt()}% used', style: AppTextStyles.bodySmall.copyWith(color: _getProgressColor(percentage))),
              ],
            ),
            if (!isLimitReached) ...[
              Text('$remaining words left', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Files uploaded: ${usage.filesUploaded}', style: AppTextStyles.bodySmall),
                Text('Reviewers: ${usage.reviewersGenerated}', style: AppTextStyles.bodySmall),
              ],
            ),
            if (!isPro) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onUpgrade,
                  child: const Text('Upgrade to Pro ₱300/month →'),
                ),
              ),
            ],
            if (isLimitReached) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.error)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.block_rounded, color: AppColors.error, size: 20), const SizedBox(width: AppSpacing.sm), Text('Limit Reached', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))]),
                    const SizedBox(height: AppSpacing.sm),
                    Text("You've reached your weekly limit.", style: AppTextStyles.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    if (!isPro) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onUpgrade, child: const Text('Upgrade to Pro ₱300/month →'))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return AppColors.error;
    if (percentage >= 0.76) return const Color(0xFFFF5722);
    if (percentage >= 0.51) return const Color(0xFFF59E0B);
    return AppColors.primary;
  }
}
