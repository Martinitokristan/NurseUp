import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_gradient_card.dart';
import '../../../ai_reviewer/presentation/providers/reviewer_provider.dart';
import '../../../ai_reviewer/presentation/utils/reviewer_navigation.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../usage/domain/usage_limits.dart';
import '../../domain/entities/study_file_entity.dart';
import '../providers/file_manager_provider.dart';

class FileManagerPage extends ConsumerWidget {
  const FileManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(userFilesProvider);
    final files = filesAsync.valueOrNull ?? const <StudyFileEntity>[];
    final fileCount = files.length;
    final activePlan = ref.watch(activePlanProvider);
    final isPro = activePlan.isPro;
    final limits = usageLimitsForPlan(isPro);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F1A), Color(0xFF111A2E)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF4FBFF)],
          );
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
            children: [
              Row(children: [const Text('My Library', style: AppTextStyles.displayLarge), const Spacer(), IconButton.filled(onPressed: () => context.push(AppRoutes.upload), icon: const Icon(Icons.add_rounded))]),
              const SizedBox(height: 10),
              const Text('Manage your notes and generated reviewers.', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.xl),
              AppGradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isPro ? '$fileCount files uploaded · Pro storage' : '$fileCount / ${limits.dailyFiles} free files used today',
                            style: AppTextStyles.h3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (isPro)
                      ClipRRect(borderRadius: BorderRadius.circular(999), child: const LinearProgressIndicator(value: 1, minHeight: 10, color: AppColors.primary, backgroundColor: Colors.white))
                    else
                      ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: (fileCount / limits.dailyFiles).clamp(0.0, 1.0), minHeight: 10, color: AppColors.primary, backgroundColor: Colors.white)),
                    const SizedBox(height: 8),
                    Text(isPro ? 'Pro plan: no daily file-count cap. Word limits still apply.' : 'Free plan: ${limits.dailyFiles} files per day.', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Recent Files', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.md),
              filesAsync.when(
                data: (files) => Column(children: files.map((file) => _file(context, ref, file)).toList()),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text('Unable to load files.'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(index: 1),
    );
  }

  Widget _file(BuildContext context, WidgetRef ref, StudyFileEntity file) {
    final meta = '${(file.sizeBytes / 1000000).toStringAsFixed(1)} MB · ${file.type.toUpperCase()}';
    final reviewerId = ref.watch(reviewerIdForFileProvider(file.id));
    final generationState = ref.watch(generateReviewerControllerProvider);
    final hasReviewer = reviewerId != null && reviewerId.isNotEmpty;
    final isGenerating = generationState.isGenerating && !hasReviewer;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppGradientCard(
        padding: const EdgeInsets.all(14),
        onTap: isGenerating ? null : () => openOrGenerateReviewer(context: context, ref: ref, fileId: file.id),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Icon(hasReviewer ? Icons.menu_book_rounded : Icons.description_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(isGenerating ? 'Generating reviewer...' : hasReviewer ? 'Reviewer ready · Tap to open' : meta, style: AppTextStyles.caption),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: isGenerating ? null : () => openOrGenerateReviewer(context: context, ref: ref, fileId: file.id),
            icon: Icon(hasReviewer ? Icons.visibility_rounded : Icons.auto_awesome_rounded, size: 18),
            label: Text(isGenerating ? 'Generating' : hasReviewer ? 'Open' : 'Review'),
          ),
        ]),
      ),
    );
  }
}
