import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/usage_model.dart';
import '../../domain/usage_limits.dart';
import '../providers/usage_provider.dart';

class UsageTransparencyCard extends StatelessWidget {
  const UsageTransparencyCard({
    super.key,
    required this.usage,
    required this.isPro,
    this.onUpgrade,
  });

  final UsageModel usage;
  final bool isPro;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final limits = usageLimitsForPlan(isPro);
    final dailyWordMax = limits.dailyWords;
    final dailyWordPct = dailyWordMax > 0 ? (usage.wordsUsedToday / dailyWordMax).clamp(0.0, 1.0) : 0.0;
    final isDailyWordLimitReached = usage.wordsUsedToday >= dailyWordMax;

    final weeklyWordMax = limits.weeklyWords;
    final weeklyWordPct = weeklyWordMax > 0 ? (usage.wordsUsedThisWeek / weeklyWordMax).clamp(0.0, 1.0) : 0.0;
    final isWeeklyLimitReached = usage.wordsUsedThisWeek >= weeklyWordMax;

    final dailyFileMax = limits.dailyFiles;
    final isDailyFileLimitReached = !isPro && usage.dailyFileUploads >= dailyFileMax;
    final filesTodayLabel = isPro
        ? 'Files Today: ${usage.dailyFileUploads}'
        : 'Files Today: ${usage.dailyFileUploads} / $dailyFileMax';

    final dailyResetStr = usage.dailyResetDate != null
        ? 'Resets ${formatPhReset(usage.dailyResetDate!)}'
        : 'Starts after first upload';
    final weeklyResetStr = 'Resets ${formatPhReset(usage.weekResetDate)}';

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
              resetLabel: dailyResetStr,
              isReached: isDailyWordLimitReached,
            ),
            const SizedBox(height: AppSpacing.md),
            _UsageBar(
              label: 'This week\'s words',
              used: usage.wordsUsedThisWeek,
              max: weeklyWordMax,
              percentage: weeklyWordPct,
              resetLabel: weeklyResetStr,
              isReached: isWeeklyLimitReached,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  filesTodayLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: isDailyFileLimitReached ? AppColors.error : AppColors.textSecondary),
                ),
                Text('Total uploaded: ${usage.filesUploaded}', style: AppTextStyles.bodySmall),
              ],
            ),
            if (isDailyWordLimitReached || isWeeklyLimitReached || isDailyFileLimitReached) ...[
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
                      Text(
                        'Uploads blocked',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.xs),
                    if (isWeeklyLimitReached)
                      Text(
                        'Weekly limit reached. Daily uploads are paused until $weeklyResetStr.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                      )
                    else if (isDailyWordLimitReached)
                      Text(
                        'Daily word limit reached. You can upload again at $dailyResetStr.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                      )
                    else if (isDailyFileLimitReached)
                      Text(
                        'Daily file limit reached. You can upload again at $dailyResetStr.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                      ),
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
