import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/usage_model.dart';

class FileUploadPreviewCard extends StatelessWidget {
  const FileUploadPreviewCard({
    super.key,
    required this.fileName,
    required this.wordCount,
    required this.usage,
    required this.onUpload,
    required this.onCancel,
    required this.onUpgrade,
  });

  final String fileName;
  final int wordCount;
  final UsageModel usage;
  final VoidCallback onUpload;
  final VoidCallback onCancel;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final remaining = usage.getRemainingWords();
    final wouldExceed = wordCount > remaining;
    final afterUpload = usage.wordsUsedThisWeek + wordCount;
    final limit = usage.getWeeklyLimit();
    final isPro = usage.tier == 'pro';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.description_rounded, color: AppColors.primary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(fileName, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis))]),
            const SizedBox(height: AppSpacing.sm),
            Text('This file contains ~$wordCount words', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Text('Your weekly usage:', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: usage.getUsagePercentage().clamp(0.0, 1.0), color: _getProgressColor(usage.getUsagePercentage()), backgroundColor: AppColors.primarySurface),
            const SizedBox(height: AppSpacing.sm),
            Text('${usage.wordsUsedThisWeek} / $limit words', style: AppTextStyles.bodySmall),
            if (!wouldExceed) ...[
              Text('After upload: $afterUpload / $limit words', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text('Resets Monday, ${_formatDate(usage.weekResetDate)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (wouldExceed) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.warning)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.warning_rounded, color: AppColors.warning, size: 20), const SizedBox(width: AppSpacing.sm), Text('This file exceeds your remaining $remaining words this week.', style: AppTextStyles.bodySmall)]),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Resets Monday, ${_formatDate(usage.weekResetDate)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!isPro) SizedBox(width: double.infinity, child: AppButton(label: 'Upgrade to Pro - ₱300/month', icon: Icons.star_rounded, onPressed: onUpgrade)),
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onCancel, child: const Text('Cancel'))),
            ] else ...[
              AppButton(label: 'Upload & Generate Reviewer ✓', icon: Icons.check_circle_rounded, onPressed: onUpload),
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onCancel, child: const Text('Cancel'))),
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
