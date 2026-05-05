import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/reviewer_provider.dart';

class ReviewerGeneratingPage extends ConsumerStatefulWidget {
  const ReviewerGeneratingPage({super.key, this.fileId});

  final String? fileId;

  @override
  ConsumerState<ReviewerGeneratingPage> createState() => _ReviewerGeneratingPageState();
}

class _ReviewerGeneratingPageState extends ConsumerState<ReviewerGeneratingPage> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final effectiveFileId = widget.fileId ?? GoRouterState.of(context).uri.queryParameters['fileId'];
    final controller = ref.watch(generateReviewerControllerProvider);
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.valueOrNull;

    if (authAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please sign in before generating reviewers.', textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.onboarding),
                  child: const Text('Get Started'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_started && effectiveFileId != null && effectiveFileId.isNotEmpty) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(generateReviewerControllerProvider.notifier).generateFromFile(effectiveFileId);
      });
    }
    
    if (controller.reviewerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('${AppRoutes.reviewerDetail}?id=${controller.reviewerId}&from=generate');
      });
    }
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(32), decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome_rounded, size: 72, color: AppColors.primary)),
            const SizedBox(height: AppSpacing.xxl),
            Text(controller.message ?? 'Creating your reviewer...', style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            const Text('Reading your learning material and building a clean study guide.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            if (controller.errorMessage != null) const Icon(Icons.error_rounded, color: AppColors.error, size: 42) else const LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.primarySurface),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(controller.errorMessage!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: () => context.go(AppRoutes.files), child: const Text('Back to Library')),
            ],
          ]),
        ),
      ),
    );
  }
}
