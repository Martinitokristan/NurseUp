import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_gradient_card.dart';
import '../providers/file_manager_provider.dart';

class FileManagerPage extends ConsumerWidget {
  const FileManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(userFilesProvider);
    final usage = ref.watch(freeTierUsageProvider);
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.cloud_upload_rounded, color: AppColors.primary), const SizedBox(width: 10), Text('$usage / 3 free files used', style: AppTextStyles.h3)]),
                  const SizedBox(height: 14),
                  ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: usage / 3, minHeight: 10, color: AppColors.primary, backgroundColor: Colors.white)),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Recent Files', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.md),
              filesAsync.when(
                data: (files) => Column(children: files.map((file) => _file(context, file.name, '${(file.sizeBytes / 1000000).toStringAsFixed(1)} MB · ${file.type.toUpperCase()}')).toList()),
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

  Widget _file(BuildContext context, String name, String meta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppGradientCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.description_rounded, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: AppTextStyles.h3), const SizedBox(height: 4), Text(meta, style: AppTextStyles.caption)])),
          IconButton(onPressed: () => context.push(AppRoutes.reviewerGenerating), icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary)),
        ]),
      ),
    );
  }
}
