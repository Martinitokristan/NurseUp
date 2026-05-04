import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/reviewer_provider.dart';

class ReviewerListPage extends ConsumerWidget {
  const ReviewerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewersAsync = ref.watch(reviewersProvider);
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('My Reviewers')),
      body: reviewersAsync.when(
        data: (reviewers) => reviewers.isEmpty
            ? AppEmptyState(icon: Icons.description_rounded, title: 'No reviewers yet', message: 'Generate your first reviewer from a file.', action: ElevatedButton(onPressed: () => context.push(AppRoutes.files), child: const Text('Go to Files')))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: reviewers.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => Card(child: ListTile(onTap: () => context.push('?id='), leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary), title: Text(reviewers[index].title), subtitle: Text(reviewers[index].summary), trailing: OutlinedButton(onPressed: () => context.push('?id=&export=true'), child: const Text('Export')))),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Unable to load reviewers.')),
      ),
      bottomNavigationBar: const AppBottomNav(index: 2),
    );
  }
}

