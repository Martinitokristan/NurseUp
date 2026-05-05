import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/usage_model.dart';
import '../providers/usage_provider.dart';

class UsageTransparencyCard extends StatelessWidget {
  const UsageTransparencyCard({super.key, required this.usage, this.onUpgrade});

  final UsageModel usage;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final isPro = usage.tier == 'pro';

    final dailyWordMax = usage.getDailyWordLimit();
    final dailyWordPct = dailyWordMax > 0 ? (usage.wordsUsedToday / dailyWordMax).clamp(0.0, 1.0) : 0.0;
    final isDailyWordLimitReached = usage.isDailyLimitReached();

    final weeklyWordMax = usage.getWeeklyLimit();
    final weeklyWordPct = weeklyWordMax > 0 ? (usage.wordsUsedThisWeek / weeklyWordMax).clamp(0.0, 1.0) : 0.0;
    final isWeeklyLimitReached = usage.isLimitReached();

    final dailyFileMax = usage.getDailyFileLimit();
    final isDailyFileLimitReached = usage.isDailyFileLimitReached();

    final dailyResetStr = usage.dailyResetDate != null ? formatPhReset(usage.dailyResetDate!) : 'in 24 hrs';
    final weeklyResetStr = formatPhReset(usage.weekResetDate);

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
                Text('Usage', style: AppTextStyles.h3),
                const Spacer(),
                Text(isPro ? 'Pro Plan ⭐' : 'Free Plan',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: isPro ? AppColors.primary : AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _UsageBar(
              label: 'Today\'s words',
              used: usage.wordsUsedToday,
              max: dailyWordMax,
              percentage: dailyWordPct,
              resetLabel: 'Resets $dailyResetStr',
              isReached: isDailyWordLimitReached,
            ),
            const SizedBox(height: AppSpacing.md),
            _UsageBar(
              label: 'This week\'s words',
              used: usage.wordsUsedThisWeek,
              max: weeklyWordMax,
              percentage: weeklyWordPct,
              resetLabel: 'Resets $weeklyResetStr',
              isReached: isWeeklyLimitReached,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Files today: ${usage.dailyFileUploads} / $dailyFileMax',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: isDailyFileLimitReached ? AppColors.error : AppColors.textSecondary),
                ),
                Text('Total uploaded: ${usage.filesUploaded}', style: AppTextStyles.bodySmall),
              ],
            ),
            if (isDailyFileLimitReached) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Daily file limit reached. Resets $dailyResetStr.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            ],
            if (isDailyWordLimitReached || isWeeklyLimitReached) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.error)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.block_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Uploads blocked',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                    ]),
                    const SizedBox(height: AppSpacing.xs),
                    if (isDailyWordLimitReached)
                      Text('Daily word limit reached. Resets $dailyResetStr.',
                          style: AppTextStyles.bodySmall),
                    if (isWeeklyLimitReached)
                      Text('Weekly word limit reached. Resets $weeklyResetStr.',
                          style: AppTextStyles.bodySmall),
                    if (!isPro) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: onUpgrade,
                              child: const Text('Upgrade to Pro ₱300/month →'))),
                    ],
                  ],
                ),
              ),
            ],
            if (!isPro && !isDailyWordLimitReached && !isWeeklyLimitReached) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: onUpgrade,
                    child: const Text('Upgrade to Pro ₱300/month →')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.label,
    required this.used,
    required this.max,
    required this.percentage,
    required this.resetLabel,
    required this.isReached,
  });

  final String label;
  final int used;
  final int max;
  final double percentage;
  final String resetLabel;
  final bool isReached;

  Color _color() {
    if (percentage >= 1.0) return AppColors.error;
    if (percentage >= 0.76) return const Color(0xFFFF5722);
    if (percentage >= 0.51) return const Color(0xFFF59E0B);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            Text('$used / $max words',
                style: AppTextStyles.bodySmall.copyWith(color: _color())),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
            value: percentage,
            color: _color(),
            backgroundColor: AppColors.primarySurface),
        const SizedBox(height: 4),
        Text(resetLabel,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
